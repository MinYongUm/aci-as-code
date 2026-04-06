# =============================================================================
# Module: tenant
# 파일: main.tf
# 역할: ACI Tenant와 VRF(Virtual Routing and Forwarding)를 생성한다
#
# ACI 오브젝트 계층:
#   Tenant (fvTenant)   → 관리 도메인의 최상위 단위 (회사/부서/프로젝트 단위)
#   └── VRF (fvCtx)     → Tenant 내 독립된 라우팅 도메인 (IP 주소 공간 분리)
#
# DN(Distinguished Name) 경로:
#   Tenant → uni/tn-{name}
#   VRF    → uni/tn-{tenant_name}/ctx-{name}
#
# 실무 비유:
#   Tenant = 건물 전체를 빌린 회사 (다른 회사와 완전 분리)
#   VRF    = 그 회사 안의 층별 독립 네트워크 (개발팀/운영팀 IP 분리)
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
# 리소스: aci_tenant
# ACI 오브젝트: fvTenant
# 역할: Tenant를 생성한다
#
# Terraform 리소스 문법:
#   resource "리소스_타입" "로컬_이름" { ... }
#   - 리소스_타입: CiscoDevNet/aci Provider가 제공하는 타입
#   - 로컬_이름: 이 .tf 파일 안에서만 사용하는 참조 이름 (ACI에 반영 안 됨)
#   - "this" 는 단일 리소스일 때 관용적으로 사용하는 로컬 이름
# -----------------------------------------------------------------------------
resource "aci_tenant" "this" {
  # name: APIC에 생성될 실제 Tenant 이름
  # var.tenant_name → variables.tf에서 정의한 입력 변수
  name        = var.tenant_name

  # description: APIC GUI의 Description 필드에 표시됨
  description = var.tenant_description
}


# -----------------------------------------------------------------------------
# 리소스: aci_vrf
# ACI 오브젝트: fvCtx
# 역할: Tenant 하위에 VRF를 생성한다
# -----------------------------------------------------------------------------
resource "aci_vrf" "this" {
  # tenant_dn: 이 VRF가 속할 Tenant의 DN
  # aci_tenant.this.id → 위에서 생성한 Tenant 리소스의 DN을 참조
  # Terraform이 자동으로 Tenant 먼저 생성 → VRF 생성 순서를 보장함
  tenant_dn = aci_tenant.this.id

  name        = var.vrf_name
  description = var.vrf_description

  # pc_enf_pref: VRF의 Policy Enforcement 방향 설정
  #   "enforced"   → Contract 없이는 EPG 간 통신 차단 (보안 강화, 기본값)
  #   "unenforced" → Contract 없어도 EPG 간 통신 허용 (테스트/개발 환경)
  pc_enf_pref = var.vrf_enforcement

  # knw_mcast_act: 알려진 멀티캐스트 주소 처리 방식
  #   "permit" → 멀티캐스트 허용 (일반적인 설정)
  #   "deny"   → 멀티캐스트 차단
  #knw_mcast_act = "permit"
}
