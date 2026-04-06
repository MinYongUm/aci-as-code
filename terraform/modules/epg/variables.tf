# =============================================================================
# Module: epg
# 파일: variables.tf
# 역할: Application Profile, EPG, Contract 바인딩에 필요한 입력 변수 정의
# =============================================================================


# -----------------------------------------------------------------------------
# 상위 오브젝트 참조 변수
# -----------------------------------------------------------------------------

variable "tenant_dn" {
  type        = string
  description = "이 AP/EPG가 속할 Tenant의 DN (예: uni/tn-demo-tenant)"
}

variable "bd_dn" {
  type        = string
  description = "EPG를 연결할 Bridge Domain의 DN (예: uni/tn-demo-tenant/BD-web-bd)"
  # networking 모듈의 output.bd_dn 값을 전달받음
}


# -----------------------------------------------------------------------------
# Application Profile 변수
# -----------------------------------------------------------------------------

variable "ap_name" {
  type        = string
  description = "Application Profile 이름 (ACI 오브젝트: fvAp.name)"
}

variable "ap_description" {
  type        = string
  description = "Application Profile 설명"
  default     = ""
}


# -----------------------------------------------------------------------------
# EPG 변수
# -----------------------------------------------------------------------------

variable "epg_name" {
  type        = string
  description = "EPG 이름 (ACI 오브젝트: fvAEPg.name)"
}

variable "epg_description" {
  type        = string
  description = "EPG 설명"
  default     = ""
}


# -----------------------------------------------------------------------------
# Contract 바인딩 변수
# -----------------------------------------------------------------------------

variable "contracts" {
  # list(object(...)): 하나의 EPG에 여러 Contract를 바인딩할 수 있음
  type = list(object({
    contract_dn   = string # 연결할 Contract의 DN
    contract_type = string # "provider" 또는 "consumer"
  }))
  description = <<-EOT
    EPG에 바인딩할 Contract 목록
    contract_dn   : policy 모듈의 output.contract_dn 값
    contract_type : "provider" (서비스 제공 EPG) | "consumer" (서비스 소비 EPG)
  EOT
  default = []

  validation {
    # alltrue(): 리스트 안의 모든 조건이 true일 때만 통과
    condition = alltrue([
      for c in var.contracts : contains(["provider", "consumer"], c.contract_type)
    ])
    error_message = "contract_type 값은 'provider' 또는 'consumer' 이어야 합니다."
  }
}
