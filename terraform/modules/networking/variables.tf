# =============================================================================
# Module: networking
# 파일: variables.tf
# 역할: Bridge Domain 및 Subnet 생성에 필요한 입력 변수를 정의한다
# =============================================================================


# -----------------------------------------------------------------------------
# 상위 오브젝트 참조 변수 (tenant 모듈 output에서 전달받음)
# -----------------------------------------------------------------------------

variable "tenant_dn" {
  type        = string
  description = "이 BD가 속할 Tenant의 DN (예: uni/tn-demo-tenant)"
  # tenant 모듈의 output.tenant_dn 값을 전달받음
}

variable "vrf_dn" {
  type        = string
  description = "BD를 연결할 VRF의 DN (예: uni/tn-demo-tenant/ctx-prod-vrf)"
  # tenant 모듈의 output.vrf_dn 값을 전달받음
}


# -----------------------------------------------------------------------------
# Bridge Domain 변수
# -----------------------------------------------------------------------------

variable "bd_name" {
  type        = string
  description = "Bridge Domain 이름 (ACI 오브젝트: fvBD.name)"
}

variable "bd_description" {
  type        = string
  description = "Bridge Domain 설명"
  default     = ""
}

variable "unicast_route" {
  type        = string
  description = <<-EOT
    L3 유니캐스트 라우팅 활성화 여부
      "yes" → BD가 L3 게이트웨이 역할 수행 (일반적인 운영 환경, 권장)
      "no"  → L2 only 모드 (레거시 환경 또는 특수 목적)
  EOT
  default     = "yes"

  validation {
    condition     = contains(["yes", "no"], var.unicast_route)
    error_message = "unicast_route 값은 'yes' 또는 'no' 이어야 합니다."
  }
}

variable "arp_flood" {
  type        = string
  description = <<-EOT
    ARP Flooding 활성화 여부
      "no"  → ARP Proxy 사용 (unicast_route=yes 환경 권장, 브로드캐스트 감소)
      "yes" → 전통적인 ARP 플러딩 (L2 only 또는 특수 상황)
  EOT
  default     = "no"

  validation {
    condition     = contains(["yes", "no"], var.arp_flood)
    error_message = "arp_flood 값은 'yes' 또는 'no' 이어야 합니다."
  }
}


# -----------------------------------------------------------------------------
# Subnet 변수
# -----------------------------------------------------------------------------

variable "subnets" {
  # list(object(...)): 여러 개의 Subnet을 한 번에 정의할 수 있는 구조
  # 하나의 BD에 복수 Subnet 연결 가능 (예: IPv4 + IPv6 Dual-stack)
  type = list(object({
    ip          = string       # 게이트웨이 IP/Prefix (예: 10.10.1.1/24)
    scope       = list(string) # ["private"] / ["public"] / ["shared"]
    description = string       # Subnet 설명
  }))
  description = <<-EOT
    BD에 연결할 Subnet 목록
    ip    : 게이트웨이 주소/prefix (호스트 IP가 아닌 GW IP 입력)
    scope : private(내부전용) | public(L3Out 광고) | shared(VRF 간 공유)
  EOT
  default = []
}
