# =============================================================================
# Module: tenant
# 파일: outputs.tf
# 역할: 이 모듈이 외부로 노출하는 출력 값을 정의한다
#
# Terraform Output 용도:
#   1. 모듈 간 연결 → 다른 모듈이 이 모듈의 결과값(DN 등)을 참조할 때 사용
#      예) networking 모듈이 tenant_dn을 받아서 BD를 Tenant 하위에 생성
#   2. 최종 확인   → terraform apply 완료 후 생성된 오브젝트 DN을 터미널에 출력
#
# DN(Distinguished Name):
#   ACI의 모든 오브젝트는 고유한 DN을 가짐
#   Terraform에서 리소스의 .id 속성이 DN에 해당
#   예) aci_tenant.this.id = "uni/tn-demo-tenant"
# =============================================================================


# -----------------------------------------------------------------------------
# Tenant 출력값
# -----------------------------------------------------------------------------

output "tenant_dn" {
  # value: 실제로 출력할 값
  # aci_tenant.this.id → 생성된 Tenant의 DN (uni/tn-{name})
  value       = aci_tenant.this.id
  description = "Tenant DN — 다른 모듈에서 tenant_dn으로 참조 (예: uni/tn-demo-tenant)"
}

output "tenant_name" {
  value       = aci_tenant.this.name
  description = "생성된 Tenant의 이름"
}


# -----------------------------------------------------------------------------
# VRF 출력값
# -----------------------------------------------------------------------------

output "vrf_dn" {
  # networking 모듈에서 BD를 VRF에 연결할 때 이 값을 사용
  value       = aci_vrf.this.id
  description = "VRF DN — BD를 VRF에 연결할 때 사용 (예: uni/tn-demo-tenant/ctx-prod-vrf)"
}

output "vrf_name" {
  value       = aci_vrf.this.name
  description = "생성된 VRF의 이름"
}
