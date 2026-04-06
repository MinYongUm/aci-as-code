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
# 리소스: aci_application_profile
# ACI 오브젝트: fvAp
# 역할: EPG들을 묶는 Application Profile을 생성한다
# -----------------------------------------------------------------------------
resource "aci_application_profile" "this" {
  # parent_dn: 이 AP가 속할 Tenant DN
  parent_dn   = var.tenant_dn  
  name        = var.ap_name
  description = var.ap_description
}


# -----------------------------------------------------------------------------
# 리소스: aci_application_epg
# ACI 오브젝트: fvAEPg
# 역할: EPG를 생성하고 Bridge Domain에 연결한다
# -----------------------------------------------------------------------------
resource "aci_application_epg" "this" {
  # application_profile_dn: 이 EPG가 속할 AP의 DN
  application_profile_dn = aci_application_profile.this.id

  name        = var.epg_name
  description = var.epg_description

  # relation_fv_rs_bd: 이 EPG가 사용할 Bridge Domain의 DN
  # EPG는 반드시 BD에 연결되어야 L2/L3 통신이 가능
  # BD를 통해 VRF → 라우팅 도메인까지 연결됨
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
#   예) allow-http Contract:
#       web-epg (Provider) ← HTTP 요청 ← external (Consumer)
#
# for_each 키 설계:
#   "${c.contract_type}_${basename(c.contract_dn)}"
#   예) "provider_brc-allow-http" / "consumer_brc-allow-http"
#   → 동일 Contract를 Provider/Consumer로 동시에 바인딩할 때 키 충돌 방지
#   → basename()은 DN 문자열의 마지막 세그먼트만 추출하는 함수
#      (예: "uni/tn-demo/brc-allow-http" → "brc-allow-http")
# -----------------------------------------------------------------------------
resource "aci_epg_to_contract" "this" {
  # idx(인덱스)는 plan 단계에서 항상 확정되는 정적 값
  # contract_dn은 키가 아닌 값(value)에만 사용 → 오류 해소
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
