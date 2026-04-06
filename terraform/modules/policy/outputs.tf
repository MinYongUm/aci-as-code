# =============================================================================
# Module: policy
# 파일: outputs.tf
# 역할: 생성된 Contract, Filter, Subject의 DN을 외부로 노출한다
#
# 주요 사용처:
#   epg 모듈 → contract_dn을 받아서 EPG에 Contract를 바인딩
# =============================================================================


output "contract_dn" {
  # epg 모듈의 contracts 변수에서 contract_dn으로 참조
  value       = aci_contract.this.id
  description = "Contract DN (예: uni/tn-demo-tenant/brc-allow-http)"
}

output "contract_name" {
  value       = aci_contract.this.name
  description = "생성된 Contract 이름"
}

output "filter_dns" {
  # for_each로 생성된 Filter 리소스의 DN 맵
  # 키: filter 이름 (예: "filter-http")
  # 값: filter DN (예: "uni/tn-demo-tenant/flt-filter-http")
  value       = { for k, v in aci_filter.this : k => v.id }
  description = "Filter DN 맵 (예: {\"filter-http\" = \"uni/tn-.../flt-filter-http\"})"
}

output "subject_dn" {
  value       = aci_contract_subject.this.id
  description = "Contract Subject DN (예: uni/tn-demo-tenant/brc-allow-http/subj-http-subj)"
}
