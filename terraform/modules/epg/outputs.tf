# =============================================================================
# Module: epg
# 파일: outputs.tf
# 역할: 생성된 AP, EPG의 DN을 외부로 노출한다
#
# 변경 포인트 (Scenario 02 대응):
#   ap_dn  : aci_application_profile.this.id  →  local.ap_dn
#             create_ap = false 시 리소스가 없으므로 직접 참조하면 오류 발생
#             local.ap_dn이 create_ap 여부에 따라 올바른 값을 보장
#
#   ap_name: aci_application_profile.this.name  →  var.ap_name
#             count = 0인 경우 리소스 속성 참조 불가
#             변수 값은 항상 존재하므로 안전하게 참조 가능
#
# 주요 사용처:
#   - scenarios/02_three_tier_app/main.tf
#     module.app_epg.existing_ap_dn = module.web_epg.ap_dn  ← 이 output 사용
#     module.db_epg.existing_ap_dn  = module.web_epg.ap_dn  ← 이 output 사용
# =============================================================================


output "ap_dn" {
  # local.ap_dn:
  #   create_ap = true  → aci_application_profile.this[0].id (신규 생성 AP DN)
  #   create_ap = false → var.existing_ap_dn (전달받은 기존 AP DN)
  value       = local.ap_dn
  description = "Application Profile DN (예: uni/tn-demo-tenant/ap-demo-ap)"
}

output "ap_name" {
  # var.ap_name: 리소스 속성 대신 변수 직접 참조
  # create_ap = false 시 aci_application_profile.this가 없으므로
  # .name 속성 참조 시 오류 발생 → 변수 값으로 안전하게 대체
  value       = var.ap_name
  description = "Application Profile 이름"
}

output "epg_dn" {
  value       = aci_application_epg.this.id
  description = "EPG DN (예: uni/tn-demo-tenant/ap-demo-ap/epg-web-epg)"
}

output "epg_name" {
  value       = aci_application_epg.this.name
  description = "생성된 EPG 이름"
}