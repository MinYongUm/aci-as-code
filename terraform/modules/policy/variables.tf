# =============================================================================
# Module: policy
# 파일: variables.tf
# 역할: Contract, Subject, Filter, Entry 생성에 필요한 입력 변수 정의
# =============================================================================


# -----------------------------------------------------------------------------
# 상위 오브젝트 참조 변수
# -----------------------------------------------------------------------------

variable "tenant_dn" {
  type        = string
  description = "이 Contract/Filter가 속할 Tenant의 DN (예: uni/tn-demo-tenant)"
}


# -----------------------------------------------------------------------------
# Contract 변수
# -----------------------------------------------------------------------------

variable "contract_name" {
  type        = string
  description = "Contract 이름 (ACI 오브젝트: vzBrCP.name)"
}

variable "contract_description" {
  type        = string
  description = "Contract 설명"
  default     = ""
}

variable "contract_scope" {
  type        = string
  description = <<-EOT
    Contract 적용 범위
      "tenant"              → 동일 Tenant 내 EPG 간 적용 (가장 일반적)
      "vrf"                 → 동일 VRF 내 EPG 간 적용
      "global"              → Tenant 경계 초월 적용 (공용 서비스)
      "application-profile" → 동일 AP 내 EPG 간 적용
  EOT
  default     = "tenant"

  validation {
    condition     = contains(["tenant", "vrf", "global", "application-profile"], var.contract_scope)
    error_message = "contract_scope 값은 'tenant', 'vrf', 'global', 'application-profile' 중 하나이어야 합니다."
  }
}


# -----------------------------------------------------------------------------
# Subject 변수
# -----------------------------------------------------------------------------

variable "subject_name" {
  type        = string
  description = "Contract Subject 이름 (ACI 오브젝트: vzSubj.name)"
}

variable "subject_description" {
  type        = string
  description = "Contract Subject 설명"
  default     = ""
}


# -----------------------------------------------------------------------------
# Filter 변수
# -----------------------------------------------------------------------------

variable "filters" {
  # map(object(...)): Filter 이름을 키로, 상세 정의를 값으로 가지는 맵
  # 예시:
  #   filters = {
  #     "filter-http" = {
  #       description = "HTTP Filter"
  #       entries = [
  #         { name="tcp-80", ether_t="ip", ip_proto="tcp",
  #           d_from_port="http", d_to_port="http", description="Allow HTTP" },
  #         { name="tcp-443", ether_t="ip", ip_proto="tcp",
  #           d_from_port="https", d_to_port="https", description="Allow HTTPS" }
  #       ]
  #     }
  #   }
  type = map(object({
    description = string
    entries = list(object({
      name        = string # Entry 이름 (ACI 오브젝트: vzEntry.name)
      ether_t     = string # L3 프로토콜: "ip" | "arp" | "unspecified"
      ip_proto    = string # L4 프로토콜: "tcp" | "udp" | "icmp" | "unspecified"
      d_from_port = string # 목적지 포트 시작 (숫자 or named: "http", "https", "dns" 등)
      d_to_port   = string # 목적지 포트 끝   (단일 포트: d_from_port와 동일하게 입력)
      description = string # Entry 설명
    }))
  }))
  description = "Filter 및 Filter Entry 정의 맵 (Filter 이름을 키로 사용)"
}
