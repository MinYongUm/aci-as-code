# =============================================================================
# Scenario 01 — Basic Tenant
# 파일: variables.tf
# 역할: 이 시나리오 전체에서 사용하는 입력 변수를 정의한다
#
# 실제 값은 terraform.tfvars에 입력 (이 파일에는 타입/설명/기본값만 정의)
# terraform.tfvars → .gitignore 등록 필수 (크리덴셜 보호)
#
# 구현 대상 ACI 오브젝트 계층:
#   Tenant(demo-tenant)
#   └── VRF(prod-vrf)
#       └── BD(web-bd) + Subnet(10.10.1.1/24)
#           └── AP(demo-ap)
#               └── EPG(web-epg)
#                   └── Contract(allow-http) ── Subject(http-subj)
#                                               └── Filter(filter-http)
#                                                   ├── Entry(tcp-80)
#                                                   └── Entry(tcp-443)
# =============================================================================


# -----------------------------------------------------------------------------
# [1] ACI Provider 접속 정보
#     실제 값: terraform.tfvars에서 입력
# -----------------------------------------------------------------------------

variable "aci_url" {
  type        = string
  description = "APIC 접속 URL (예: https://sandboxapicdc.cisco.com)"
  # default 없음 → 필수 변수: terraform.tfvars에 반드시 입력해야 함
}

variable "aci_username" {
  type        = string
  description = "APIC 로그인 계정 (예: admin)"
}

variable "aci_password" {
  type        = string
  description = "APIC 로그인 비밀번호"
  # sensitive = true: plan/apply 출력 및 로그에서 값이 *** 로 마스킹됨
  # tfstate 파일에는 평문 저장되므로 운영 환경에서는 Remote State 암호화 필요
  sensitive   = true
}

variable "aci_insecure" {
  type        = bool
  description = "TLS 인증서 검증 비활성화 여부 (Sandbox/개발환경: true, 운영환경: false)"
  default     = true
}


# -----------------------------------------------------------------------------
# [2] Tenant / VRF
# -----------------------------------------------------------------------------

variable "tenant_name" {
  type        = string
  description = "Tenant 이름 (ACI 오브젝트: fvTenant.name)"
  default     = "demo-tenant"
}

variable "tenant_description" {
  type        = string
  description = "Tenant 설명"
  default     = "Scenario 01 - Basic Tenant"
}

variable "vrf_name" {
  type        = string
  description = "VRF 이름 (ACI 오브젝트: fvCtx.name)"
  default     = "prod-vrf"
}

variable "vrf_description" {
  type        = string
  description = "VRF 설명"
  default     = "Production VRF"
}


# -----------------------------------------------------------------------------
# [3] Bridge Domain / Subnet
# -----------------------------------------------------------------------------

variable "bd_name" {
  type        = string
  description = "Bridge Domain 이름 (ACI 오브젝트: fvBD.name)"
  default     = "web-bd"
}

variable "bd_description" {
  type        = string
  description = "Bridge Domain 설명"
  default     = "Web Bridge Domain"
}

variable "bd_subnets" {
  type = list(object({
    ip          = string       # 게이트웨이 IP/Prefix (예: 10.10.1.1/24)
    scope       = list(string) # ["private"] | ["public"] | ["shared"]
    description = string
  }))
  description = <<-EOT
    BD에 연결할 Subnet 목록
    ip    : 게이트웨이 주소/prefix (네트워크 주소가 아닌 GW IP 입력)
            예) 10.10.1.0/24 네트워크 → "10.10.1.1/24"
    scope : private(내부전용) | public(L3Out 외부 광고) | shared(VRF 간 공유)
  EOT
  default = [
    {
      ip          = "10.10.1.1/24"
      scope       = ["private"]
      description = "Web Subnet GW"
    }
  ]
}


# -----------------------------------------------------------------------------
# [4] Application Profile / EPG
# -----------------------------------------------------------------------------

variable "ap_name" {
  type        = string
  description = "Application Profile 이름 (ACI 오브젝트: fvAp.name)"
  default     = "demo-ap"
}

variable "ap_description" {
  type        = string
  description = "Application Profile 설명"
  default     = "Demo Application Profile"
}

variable "epg_name" {
  type        = string
  description = "EPG 이름 (ACI 오브젝트: fvAEPg.name)"
  default     = "web-epg"
}

variable "epg_description" {
  type        = string
  description = "EPG 설명"
  default     = "Web EPG"
}


# -----------------------------------------------------------------------------
# [5] Contract
# -----------------------------------------------------------------------------

variable "contract_name" {
  type        = string
  description = "Contract 이름 (ACI 오브젝트: vzBrCP.name)"
  default     = "allow-http"
}

variable "contract_description" {
  type        = string
  description = "Contract 설명"
  default     = "Allow HTTP/HTTPS traffic"
}

variable "contract_scope" {
  type        = string
  description = "Contract 범위: tenant | vrf | global | application-profile"
  default     = "tenant"
}

variable "subject_name" {
  type        = string
  description = "Contract Subject 이름 (ACI 오브젝트: vzSubj.name)"
  default     = "http-subj"
}
