# =============================================================================
# Module: networking
# 파일: outputs.tf
# 역할: 생성된 BD와 Subnet의 DN을 외부로 노출한다
#
# 주요 사용처:
#   epg 모듈 → bd_dn을 받아서 EPG를 BD에 연결 (relation_fv_rs_bd)
# =============================================================================


output "bd_dn" {
  # epg 모듈에서 EPG를 BD에 연결할 때 이 값을 사용
  value       = aci_bridge_domain.this.id
  description = "Bridge Domain DN (예: uni/tn-demo-tenant/BD-web-bd)"
}

output "bd_name" {
  value       = aci_bridge_domain.this.name
  description = "생성된 Bridge Domain 이름"
}

output "subnet_dns" {
  # for_each로 생성된 리소스의 output은 map 형태로 반환됨
  # 키: 입력한 IP (예: "10.10.1.1/24")
  # 값: 해당 Subnet의 DN
  value       = { for k, v in aci_subnet.this : k => v.id }
  description = "Subnet DN 맵 (예: {\"10.10.1.1/24\" = \"uni/tn-.../BD-.../subnet-[10.10.1.1/24]\"})"
}