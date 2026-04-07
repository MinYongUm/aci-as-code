# =============================================================================
# Module: networking
# 파일: main.tf
# 역할: Bridge Domain(BD)과 Subnet을 생성하고 VRF에 연결한다
#
# ACI 오브젝트 계층:
#   VRF (fvCtx)              → 상위 모듈(tenant)에서 전달받음
#   └── Bridge Domain (fvBD) → L2 브로드캐스트 도메인 (VLAN과 유사한 개념)
#       └── Subnet (fvSubnet)→ BD의 게이트웨이 IP / 라우팅 범위 정의
#
# DN 경로:
#   BD     → uni/tn-{tenant}/BD-{name}
#   Subnet → uni/tn-{tenant}/BD-{bd_name}/subnet-[{ip}]
#
# 실무 비유:
#   BD     = ACI에서의 VLAN (L2 영역)
#   Subnet = 그 VLAN의 게이트웨이 IP + 서브넷 마스크
#            ACI의 SVI(Switch Virtual Interface)에 해당
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
# 리소스: aci_bridge_domain
# ACI 오브젝트: fvBD
# 역할: Bridge Domain을 생성하고 VRF에 연결한다
# -----------------------------------------------------------------------------
resource "aci_bridge_domain" "this" {
  # parent_dn: 이 BD가 속할 Tenant DN
  # 상위 모듈(tenant)의 output → 이 모듈의 variable로 전달받은 값
  parent_dn = var.tenant_dn

  name        = var.bd_name
  description = var.bd_description

  # relation_fv_rs_ctx: 이 BD를 연결할 VRF의 DN
  # ACI에서 BD는 반드시 하나의 VRF에 속해야 함
  # 미설정 시 "common" Tenant의 default VRF에 연결됨 (권장하지 않음)
  relation_fv_rs_ctx = var.vrf_dn

  # unicast_route: L3 유니캐스트 라우팅 활성화 여부
  #   "yes" → BD가 게이트웨이 역할 수행 (일반적인 L3 모드, 권장)
  #   "no"  → L2 only 모드 (레거시 환경 또는 특수 목적)
  unicast_route = var.unicast_route

  # arp_flood: ARP 요청을 브로드캐스트로 플러딩할지 여부
  #   "no"  → ARP Proxy 사용 (unicast_route="yes" 일 때 권장)
  #           ACI가 ARP를 대신 응답 → 불필요한 브로드캐스트 감소
  #   "yes" → 전통적인 ARP 플러딩 (L2 only 모드 또는 특수 상황)
  arp_flood = var.arp_flood
}


# -----------------------------------------------------------------------------
# 리소스: aci_subnet
# ACI 오브젝트: fvSubnet
# 역할: Bridge Domain에 게이트웨이 IP와 서브넷을 설정한다
#
# for_each 사용 이유:
#   하나의 BD에 여러 Subnet을 붙일 수 있음 (Dual-stack IPv4+IPv6 등)
#   variables.tf에서 subnets를 list(object)로 정의했기 때문에
#   for_each로 반복 생성
#
# for_each 키 설계:
#   { for s in var.subnets : s.ip => s }
#   → IP 주소를 키로 사용: 예) "10.10.1.1/24" => { ip, scope, description }
#   → 키가 중복되면 오류 발생 → 동일 BD에 같은 IP 두 번 입력하는 실수 방지
# -----------------------------------------------------------------------------
resource "aci_subnet" "this" {
  for_each = { for s in var.subnets : s.ip => s }

  # parent_dn: 이 Subnet이 속할 BD의 DN
  parent_dn = aci_bridge_domain.this.id

  # ip: 게이트웨이 IP 주소 (CIDR 표기법)
  # ACI Subnet은 호스트 IP가 아닌 게이트웨이 IP를 입력
  # 예) 10.10.1.0/24 네트워크라면 → "10.10.1.1/24" 입력
  ip = each.value.ip

  # scope: Subnet의 사용 범위
  #   "private" → Tenant 내부에서만 사용 (L3Out으로 외부 광고 안 함)
  #   "public"  → L3Out을 통해 외부 라우터에 광고
  #   "shared"  → 다른 Tenant의 VRF와 공유 (Shared Services 구성 시)
  scope = each.value.scope

  description = each.value.description
}
