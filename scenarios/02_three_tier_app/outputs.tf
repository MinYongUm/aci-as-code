# =============================================================================
# outputs.tf — Scenario 02: Three-Tier App
# =============================================================================
# 목적: apply 완료 후 주요 리소스 DN 출력
#
# 활용:
#   - APIC GUI에서 오브젝트 위치 확인 시 사용
#   - Ansible 연계 시 DN을 inventory 변수로 재활용 가능
#   - 다른 시나리오에서 cross-reference 시 활용
# =============================================================================

# =============================================================================
# Tenant 출력
# =============================================================================
output "tenant_dn" {
  description = "Tenant DN (uni/tn-three-tier)"
  value       = module.tenant.tenant_dn
}

# =============================================================================
# VRF 출력
# =============================================================================
output "vrf_dn" {
  description = "VRF DN (uni/tn-three-tier/ctx-app-vrf)"
  value       = module.tenant.vrf_dn    # web_networking → tenant 로 변경
}

# =============================================================================
# Bridge Domain 출력 (3계층)
# =============================================================================
output "web_bd_dn" {
  description = "Web Tier Bridge Domain DN"
  value       = module.web_networking.bd_dn
}

output "app_bd_dn" {
  description = "App Tier Bridge Domain DN"
  value       = module.app_networking.bd_dn
}

output "db_bd_dn" {
  description = "DB Tier Bridge Domain DN"
  value       = module.db_networking.bd_dn
}

# =============================================================================
# Application Profile 출력
# =============================================================================
output "ap_dn" {
  description = "Application Profile DN (uni/tn-three-tier/ap-three-tier-ap)"
  value       = module.web_epg.ap_dn
}

# =============================================================================
# EPG 출력 (3계층)
# =============================================================================
output "web_epg_dn" {
  description = "Web Tier EPG DN"
  value       = module.web_epg.epg_dn
}

output "app_epg_dn" {
  description = "App Tier EPG DN"
  value       = module.app_epg.epg_dn
}

output "db_epg_dn" {
  description = "DB Tier EPG DN"
  value       = module.db_epg.epg_dn
}

# =============================================================================
# Contract 출력 (2개)
# =============================================================================
output "web_to_app_contract_dn" {
  description = "Web→App Contract DN"
  value       = module.web_to_app_policy.contract_dn
}

output "app_to_db_contract_dn" {
  description = "App→DB Contract DN"
  value       = module.app_to_db_policy.contract_dn
}

# =============================================================================
# 요약 출력 (apply 완료 확인용)
# =============================================================================
output "scenario_summary" {
  description = "Scenario 02 구성 요약"
  value = {
    tenant   = var.tenant_name
    vrf      = var.vrf_name
    tiers = {
      web = "${var.web_epg_name} (${var.web_subnet_ip})"
      app = "${var.app_epg_name} (${var.app_subnet_ip})"
      db  = "${var.db_epg_name} (${var.db_subnet_ip})"
    }
    contracts = {
      web_to_app = "${var.web_to_app_contract_name} (TCP ${var.web_to_app_port})"
      app_to_db  = "${var.app_to_db_contract_name} (TCP ${var.app_to_db_port})"
    }
  }
}