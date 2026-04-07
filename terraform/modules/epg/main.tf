# =============================================================================
# Module: epg
# 파일: main.tf
# 역할: Application Profile, EPG를 생성하고 Contract를 바인딩한다
#
# ACI 오브젝트 계층:
#   Application Profile (fvAp)    → EPG를 묶는 논리적 컨테이너 (앱 단위 구분)
#   └── EPG (fvAEPg)              → 동일 정책을 적용받는 엔드포인트 그룹
#       ├── BD 연결               → EPG가 사용할 L2/L3 도메인 지정
#       └── Contract 바인딩       → EPG 간 허용 트래픽 정책 연결
#
# DN 경로:
#   AP  → uni/tn-{tenant}/ap-{name}
#   EPG → uni/tn-{tenant}/ap-{ap_name}/epg-{name}
#
# create_ap 플래그 동작:
#   true  → aci_application_profile 리소스 생성 (count = 1)
#            Scenario 01 전체 / Scenario 02 web_epg 모듈에서 사용
#   false → 기존 AP DN(existing_ap_dn)을 참조 (count = 0, 리소스 생성 없음)
#            Scenario 02 app_epg / db_epg 모듈에서 사용
#
# local.ap_dn 사용 이유:
#   count를 쓰면 리소스가 list로 반환됨 (aci_application_profile.this[0].id)
#   EPG와 output이 create_ap 여부에 따라 분기 없이 항상 동일한 방식으로
#   AP DN을 참조할 수 있도록 local 한 곳에서 처리.
#
# 실무 비유:
#   Application Profile = 3계층 웹 앱 전체 (web + app + db 묶음)
#   EPG                 = 각 계층 (web 서버들 / app 서버들 / db 서버들)
#   Contract            = EPG 간 방화벽 정책 (web→app 8080 허용 등)
# =============================================================================


# 모듈 내 Provider 출처 선언
# Terraform 0.13+: 모듈이 비(非)HashiCorp Provider를 사용할 경우
# 모듈 자체에도 required_providers를 선언해야 올바른 출처로 연결됨
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}


# -----------------------------------------------------------------------------
# locals: AP DN을 create_ap 여부에 따라 단일 값으로 통일
#
# create_ap = true  → 새로 생성한 AP 리소스의 id 사용
#                     (aci_application_profile.this[0].id)
# create_ap = false → 호출자가 전달한 existing_ap_dn 사용
#
# 이 local을 쓰는 이유:
#   count 방식은 리소스를 list로 만들기 때문에 아래 EPG나 output에서
#   직접 참조하면 create_ap 분기마다 코드가 달라져 유지보수가 어려워짐.
#   local.ap_dn 한 곳에서만 분기를 처리하면 나머지 코드는 단일하게 유지됨.
# -----------------------------------------------------------------------------
locals {
  ap_dn = var.create_ap ? aci_application_profile.this[0].id : var.existing_ap_dn
}


# -----------------------------------------------------------------------------
# 리소스: aci_application_profile
# ACI 오브젝트: fvAp
# 역할: EPG들을 묶는 Application Profile을 생성한다
#
# count 조건:
#   create_ap = true  → count = 1 → AP 리소스 1개 생성
#   create_ap = false → count = 0 → 리소스 생성 건너뜀
#
# Scenario 01 호환성:
#   create_ap 기본값이 true이므로 Scenario 01 기존 코드 수정 불필요
# -----------------------------------------------------------------------------
resource "aci_application_profile" "this" {
  count = var.create_ap ? 1 : 0

  # parent_dn: 이 AP가 속할 Tenant DN
  parent_dn   = var.tenant_dn
  name        = var.ap_name
  description = var.ap_description
}


# -----------------------------------------------------------------------------
# 리소스: aci_application_epg
# ACI 오브젝트: fvAEPg
# 역할: EPG를 생성하고 Bridge Domain에 연결한다
#
# v2.18 속성 변경:
#   application_profile_dn (deprecated) → parent_dn
# -----------------------------------------------------------------------------
resource "aci_application_epg" "this" {
  # parent_dn: 이 EPG가 속할 AP의 DN (v2.18 최신 속성명)
  # local.ap_dn → create_ap 여부와 무관하게 항상 유효한 AP DN 보장
  parent_dn = local.ap_dn

  name        = var.epg_name
  description = var.epg_description

  relation_fv_rs_bd = var.bd_dn
}


# -----------------------------------------------------------------------------
# 리소스: aci_epg_to_contract
# ACI 오브젝트: fvRsProv (provider) / fvRsCons (consumer)
# 역할: EPG에 Contract를 Provider 또는 Consumer로 바인딩한다
#
# ACI Contract 방향 개념:
#   Provider → 서비스를 제공하는 EPG (서버 역할)
#              Contract에 정의된 트래픽을 "받는" 쪽
#   Consumer → 서비스를 소비하는 EPG (클라이언트 역할)
#              Contract에 정의된 트래픽을 "보내는" 쪽
#
# Scenario 02 Contract 방향:
#   allow-web-to-app : web-epg(Consumer) → app-epg(Provider)  TCP 8080
#   allow-app-to-db  : app-epg(Consumer) → db-epg(Provider)   TCP 3306
#
# for_each 키 설계: "${contract_type}_${idx}"
#   idx(인덱스)는 plan 단계에서 항상 확정되는 정적 값
#   contract_dn은 키가 아닌 값(value)에만 사용 → plan 시 미확정 오류 방지
#   예) "consumer_0", "provider_0", "consumer_1"
# -----------------------------------------------------------------------------
resource "aci_epg_to_contract" "this" {
  for_each = {
    for idx, c in var.contracts :
    "${c.contract_type}_${idx}" => c
  }

  # application_epg_dn: Contract를 바인딩할 EPG의 DN
  application_epg_dn = aci_application_epg.this.id

  # contract_dn: 연결할 Contract의 DN
  # policy 모듈의 output.contract_dn 값을 전달받음
  contract_dn = each.value.contract_dn

  # contract_type: "provider" 또는 "consumer"
  contract_type = each.value.contract_type
}