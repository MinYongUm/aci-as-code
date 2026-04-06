# =============================================================================
# Module: epg
# 파일: outputs.tf
# 역할: 생성된 AP, EPG의 DN을 외부로 노출한다
#
# 주요 사용처:
#   - 루트 모듈(scenarios/01_basic_tenant)의 outputs.tf에서 최종 확인용으로 출력
#   - Scenario 02, 03에서 EPG 간 Contract 연결 시 참조
# =============================================================================


output "ap_dn" {
  value       = aci_application_profile.this.id
  description = "Application Profile DN (예: uni/tn-demo-tenant/ap-demo-ap)"
}

output "ap_name" {
  value       = aci_application_profile.this.name
  description = "생성된 Application Profile 이름"
}

output "epg_dn" {
  value       = aci_application_epg.this.id
  description = "EPG DN (예: uni/tn-demo-tenant/ap-demo-ap/epg-web-epg)"
}

output "epg_name" {
  value       = aci_application_epg.this.name
  description = "생성된 EPG 이름"
}
