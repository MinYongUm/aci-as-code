# =============================================================================
# Module: policy
# 파일: main.tf
# 역할: Filter, Contract, Subject를 생성한다 (ACI 트래픽 정책의 핵심)
#
# ACI 정책 오브젝트 계층:
#   Contract (vzBrCP)           → 허용할 트래픽 정책의 최상위 단위
#   └── Subject (vzSubj)        → Contract 안의 세부 규칙 묶음
#       └── Filter (vzFilter)   → 실제 트래픽 매칭 조건 (L3/L4)
#           └── Entry (vzEntry) → 프로토콜/포트 단위의 개별 규칙
#
# DN 경로:
#   Filter   → uni/tn-{tenant}/flt-{name}
#   Entry    → uni/tn-{tenant}/flt-{filter}/e-{name}
#   Contract → uni/tn-{tenant}/brc-{name}
#   Subject  → uni/tn-{tenant}/brc-{contract}/subj-{name}
#
# 실무 비유:
#   Contract = 방화벽 정책 그룹 이름 (예: allow-http)
#   Subject  = 정책 그룹 안의 규칙 묶음 (예: http-subj)
#   Filter   = ACL 조건 정의 (예: filter-http)
#   Entry    = 실제 ACE (예: tcp dst 80, tcp dst 443)
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
# locals 블록: 반복 생성에 필요한 로컬 변수를 계산한다
#
# 문제: variables.tf에서 filters를 아래 구조로 받음
#   filters = {
#     "filter-http" = {
#       entries = [ {name="tcp-80", ...}, {name="tcp-443", ...} ]
#     }
#   }
#
# 목표: aci_filter_entry는 filter + entry 조합으로 개별 리소스를 만들어야 함
#   → "filter-http" + "tcp-80" → 리소스 1개
#   → "filter-http" + "tcp-443" → 리소스 1개
#
# flatten(): 중첩 리스트를 1차원으로 펼치는 Terraform 내장 함수
# =============================================================================
locals {
  # filter_entries: filter 이름과 entry를 조합한 단일 리스트 생성
  # 예시 결과:
  # [
  #   { filter_name="filter-http", entry_name="tcp-80", ether_t="ip", ... },
  #   { filter_name="filter-http", entry_name="tcp-443", ether_t="ip", ... }
  # ]
  filter_entries = flatten([
    for filter_name, filter in var.filters : [
      for entry in filter.entries : {
        filter_name = filter_name
        entry_name  = entry.name
        ether_t     = entry.ether_t
        ip_proto    = entry.ip_proto
        d_from_port = entry.d_from_port
        d_to_port   = entry.d_to_port
        description = entry.description
      }
    ]
  ])
}


# -----------------------------------------------------------------------------
# 리소스: aci_filter
# ACI 오브젝트: vzFilter
# 역할: 트래픽 매칭 조건 묶음(Filter)을 생성한다
#
# for_each: filters 맵의 키(filter 이름)를 기준으로 반복 생성
# 예) filters = { "filter-http" = {...} } → aci_filter.this["filter-http"]
# -----------------------------------------------------------------------------
resource "aci_filter" "this" {
  for_each = var.filters

  tenant_dn   = var.tenant_dn
  name        = each.key            # 맵의 키 = filter 이름
  description = each.value.description
}


# -----------------------------------------------------------------------------
# 리소스: aci_filter_entry
# ACI 오브젝트: vzEntry
# 역할: Filter 안에 개별 트래픽 규칙(Entry)을 생성한다
#
# for_each 키 설계: "{filter_name}__{entry_name}"
#   구분자로 __ (언더스코어 2개) 사용
#   이유: ACI 오브젝트 이름에 "-"와 "_"가 모두 사용되므로
#         단일 "-" 또는 "_"는 이름 자체와 구분이 불명확
#   예) "filter-http__tcp-80", "filter-http__tcp-443"
# -----------------------------------------------------------------------------
resource "aci_filter_entry" "this" {
  for_each = {
    for fe in local.filter_entries :
    "${fe.filter_name}__${fe.entry_name}" => fe
  }

  # filter_dn: 이 Entry가 속할 Filter의 DN
  # aci_filter.this[each.value.filter_name] → 위에서 생성한 Filter 참조
  filter_dn = aci_filter.this[each.value.filter_name].id

  name = each.value.entry_name

  # ether_t: Ethernet 타입 (L3 프로토콜)
  #   "ip"          → IPv4 (tcp/udp/icmp 사용 시 "ip" 지정)
  #   "arp"         → ARP 트래픽
  #   "unspecified" → 모든 L3 프로토콜
  ether_t = each.value.ether_t

  # proto: IP 프로토콜 번호 또는 이름
  #   "tcp" / "udp" / "icmp" / "unspecified"
  prot = each.value.ip_proto

  # d_from_port / d_to_port: 목적지 포트 범위
  #   포트 번호 직접 입력 (예: "80", "443") 또는
  #   Named port 사용 가능 (예: "http"=80, "https"=443, "dns"=53)
  #   단일 포트: d_from_port = d_to_port = "80"
  #   범위 지정: d_from_port = "8080", d_to_port = "8090"
  d_from_port = each.value.d_from_port
  d_to_port   = each.value.d_to_port

  description = each.value.description
}


# -----------------------------------------------------------------------------
# 리소스: aci_contract
# ACI 오브젝트: vzBrCP (Binary Contract Provider)
# 역할: Contract를 생성한다 (EPG 간 허용 정책의 컨테이너)
# -----------------------------------------------------------------------------
resource "aci_contract" "this" {
  tenant_dn   = var.tenant_dn
  name        = var.contract_name
  description = var.contract_description

  # scope: Contract가 적용되는 범위
  #   "tenant"              → 동일 Tenant 내 EPG 간 (가장 일반적)
  #   "vrf"                 → 동일 VRF 내 EPG 간
  #   "global"              → Tenant 경계를 넘어서 적용
  #   "application-profile" → 동일 AP 내 EPG 간
  scope = var.contract_scope
}


# -----------------------------------------------------------------------------
# 리소스: aci_contract_subject
# ACI 오브젝트: vzSubj
# 역할: Contract 안에 Subject를 생성하고 Filter를 연결한다
# -----------------------------------------------------------------------------
resource "aci_contract_subject" "this" {
  # contract_dn: 이 Subject가 속할 Contract의 DN
  contract_dn = aci_contract.this.id
  name        = var.subject_name
  description = var.subject_description

  # relation_vz_rs_subj_filt_att: 이 Subject에 연결할 Filter DN 목록
  # for 표현식으로 aci_filter.this 맵의 모든 Filter DN을 리스트로 변환
  # 예) ["uni/tn-demo/flt-filter-http"]
  relation_vz_rs_subj_filt_att = [for f in aci_filter.this : f.id]
}
