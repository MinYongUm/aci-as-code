# =============================================================================
# Module: tenant
# 파일: variables.tf
# 역할: 이 모듈이 외부(호출하는 쪽)로부터 받는 입력 변수를 정의한다
#
# Terraform 변수 문법:
#   variable "변수명" {
#     type        = 타입        # string / bool / number / list / map / object
#     description = "설명"      # terraform plan 출력 및 문서화에 사용
#     default     = 기본값      # 없으면 호출 시 반드시 값을 전달해야 함
#     sensitive   = true/false  # true이면 plan/apply 출력에서 값이 마스킹됨
#   }
# =============================================================================


# -----------------------------------------------------------------------------
# Tenant 관련 변수
# -----------------------------------------------------------------------------

variable "tenant_name" {
  # type: string → 문자열 타입
  type        = string
  description = "APIC에 생성될 Tenant 이름 (ACI 오브젝트: fvTenant.name)"
  # default 없음 → 호출 시 반드시 값을 전달해야 함 (필수 변수)
}

variable "tenant_description" {
  type        = string
  description = "Tenant 설명 (APIC GUI Description 필드에 표시)"
  # default = "" → 빈 문자열: 설명을 생략해도 오류가 나지 않음 (선택 변수)
  default     = ""
}


# -----------------------------------------------------------------------------
# VRF 관련 변수
# -----------------------------------------------------------------------------

variable "vrf_name" {
  type        = string
  description = "APIC에 생성될 VRF 이름 (ACI 오브젝트: fvCtx.name)"
}

variable "vrf_description" {
  type        = string
  description = "VRF 설명"
  default     = ""
}

variable "vrf_enforcement" {
  type        = string
  description = <<-EOT
    VRF의 Policy Enforcement 방향 설정
      "enforced"   → Contract 없으면 EPG 간 통신 차단 (운영 환경 권장)
      "unenforced" → Contract 없어도 EPG 간 통신 허용 (개발/테스트 환경)
  EOT
  default     = "enforced"

  # validation: 허용되지 않는 값이 입력되면 terraform plan 단계에서 즉시 오류 발생
  # 실제 APIC에 잘못된 값이 전달되기 전에 차단하는 역할 (조기 실패)
  validation {
    condition     = contains(["enforced", "unenforced"], var.vrf_enforcement)
    error_message = "vrf_enforcement 값은 'enforced' 또는 'unenforced' 이어야 합니다."
  }
}
