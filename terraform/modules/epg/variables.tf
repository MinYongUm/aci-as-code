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

variable "create_ap" {
  type        = bool
  description = <<-EOT
    true  → AP를 새로 생성한다 (첫 번째 EPG 모듈에서만 true)
    false → 기존 AP DN(existing_ap_dn)을 참조한다

    Scenario 01 : 항상 true (EPG 1개 → AP도 1개, 기본값 그대로 사용)
    Scenario 02 : web_epg만 true, app_epg·db_epg는 false
                  (AP 1개를 세 EPG가 공유하는 구조)
  EOT
  default     = true # 기본값 true → Scenario 01 기존 코드 영향 없음
}

variable "existing_ap_dn" {
  type        = string
  description = <<-EOT
    create_ap = false 일 때 참조할 기존 AP의 DN
    (예: uni/tn-three-tier/ap-three-tier-ap)

    create_ap = true 일 때는 이 값을 사용하지 않으므로 빈 문자열로 유지.
    Scenario 02에서는 module.web_epg.ap_dn 값을 전달받음.
  EOT
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

    Scenario 01: web-epg는 allow-http의 provider이자 consumer (단일 EPG 구조)
    Scenario 02:
      web-epg  → allow-web-to-app consumer
      app-epg  → allow-web-to-app provider + allow-app-to-db consumer
      db-epg   → allow-app-to-db provider
  EOT
  default     = []

  validation {
    # alltrue(): 리스트 안의 모든 조건이 true일 때만 통과
    condition = alltrue([
      for c in var.contracts : contains(["provider", "consumer"], c.contract_type)
    ])
    error_message = "contract_type 값은 'provider' 또는 'consumer' 이어야 합니다."
  }
}