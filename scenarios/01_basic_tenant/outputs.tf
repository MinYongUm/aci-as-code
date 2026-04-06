# =============================================================================
# Scenario 01 — Basic Tenant
# 파일: outputs.tf
# 역할: terraform apply 완료 후 생성된 ACI 오브젝트의 DN을 터미널에 출력한다
#
# 확인 방법:
#   terraform apply 완료 후 자동 출력
#   또는 언제든지: terraform output
#   특정 값만:     terraform output tenant_dn
#
# APIC GUI 검증 경로:
#   Tenants > demo-tenant > Networking > VRFs      → prod-vrf
#   Tenants > demo-tenant > Networking > BDs       → web-bd
#   Tenants > demo-tenant > Application Profiles   → demo-ap > web-epg
#   Tenants > demo-tenant > Contracts > Standard   → allow-http
# =============================================================================


# -----------------------------------------------------------------------------
# Tenant / VRF
# -----------------------------------------------------------------------------

output "tenant_dn" {
  value       = module.tenant.tenant_dn
  description = "Tenant DN (예: uni/tn-demo-tenant)"
}

output "vrf_dn" {
  value       = module.tenant.vrf_dn
  description = "VRF DN (예: uni/tn-demo-tenant/ctx-prod-vrf)"
}


# -----------------------------------------------------------------------------
# Bridge Domain / Subnet
# -----------------------------------------------------------------------------

output "bd_dn" {
  value       = module.networking.bd_dn
  description = "Bridge Domain DN (예: uni/tn-demo-tenant/BD-web-bd)"
}

output "subnet_dns" {
  # 출력 형태: { "10.10.1.1/24" = "uni/tn-demo-tenant/BD-web-bd/subnet-[10.10.1.1/24]" }
  value       = module.networking.subnet_dns
  description = "Subnet DN 맵 (키: 게이트웨이 IP)"
}


# -----------------------------------------------------------------------------
# Application Profile / EPG
# -----------------------------------------------------------------------------

output "ap_dn" {
  value       = module.epg.ap_dn
  description = "Application Profile DN (예: uni/tn-demo-tenant/ap-demo-ap)"
}

output "epg_dn" {
  value       = module.epg.epg_dn
  description = "EPG DN (예: uni/tn-demo-tenant/ap-demo-ap/epg-web-epg)"
}


# -----------------------------------------------------------------------------
# Policy (Contract / Filter / Subject)
# -----------------------------------------------------------------------------

output "contract_dn" {
  value       = module.policy.contract_dn
  description = "Contract DN (예: uni/tn-demo-tenant/brc-allow-http)"
}

output "filter_dns" {
  # 출력 형태: { "filter-http" = "uni/tn-demo-tenant/flt-filter-http" }
  value       = module.policy.filter_dns
  description = "Filter DN 맵 (키: filter 이름)"
}

output "subject_dn" {
  value       = module.policy.subject_dn
  description = "Contract Subject DN (예: uni/tn-demo-tenant/brc-allow-http/subj-http-subj)"
}
