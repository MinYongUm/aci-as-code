# =============================================================================
# variables.tf — Scenario 02: Three-Tier App
# =============================================================================
# 목적: 시나리오에서 사용하는 모든 입력 변수 정의
#
# 변수 그룹:
#   - APIC 접속 정보 (민감 변수)
#   - Tenant / VRF 설정
#   - 3계층 BD / Subnet 설정
#   - Contract / Filter 설정
#
# ⚠ tfvars 변수명은 이 파일의 variable 블록명과 반드시 일치해야 한다.
#   불일치 시 plan/apply 실행 중 직접 입력 프롬프트가 발생한다.
# =============================================================================

# -----------------------------------------------------------------------------
# APIC 접속 정보 (Scenario 01과 동일한 변수명 유지)
# -----------------------------------------------------------------------------
variable "aci_url" {
  description = "APIC URL (예: https://sandboxapicdc.cisco.com)"
  type        = string
}

variable "aci_username" {
  description = "APIC 로그인 사용자 이름"
  type        = string
}

variable "aci_password" {
  description = "APIC 로그인 비밀번호"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Tenant 설정
# ACI DN: uni/tn-<tenant_name>
# -----------------------------------------------------------------------------
variable "tenant_name" {
  description = "ACI Tenant 이름 (fvTenant)"
  type        = string
  default     = "three-tier"
}

variable "tenant_description" {
  description = "Tenant 설명"
  type        = string
  default     = "Three-Tier Application Tenant - Scenario 02"
}

# -----------------------------------------------------------------------------
# VRF 설정
# ACI DN: uni/tn-<tenant>/ctx-<vrf_name>
# -----------------------------------------------------------------------------
variable "vrf_name" {
  description = "VRF 이름 (fvCtx) — 라우팅 도메인"
  type        = string
  default     = "app-vrf"
}

variable "vrf_description" {
  description = "VRF 설명"
  type        = string
  default     = "Production VRF for Three-Tier App"
}

# -----------------------------------------------------------------------------
# Application Profile 설정
# ACI DN: uni/tn-<tenant>/ap-<ap_name>
# -----------------------------------------------------------------------------
variable "ap_name" {
  description = "Application Profile 이름 (fvAp)"
  type        = string
  default     = "three-tier-ap"
}

variable "ap_description" {
  description = "Application Profile 설명"
  type        = string
  default     = "Three-Tier Application Profile"
}

# -----------------------------------------------------------------------------
# Web Tier BD / Subnet 설정
# ACI DN: uni/tn-<tenant>/BD-<bd_name>
# 역할: 프론트엔드 웹 서버 계층 (사용자 요청 수신)
# -----------------------------------------------------------------------------
variable "web_bd_name" {
  description = "Web Tier Bridge Domain 이름 (fvBD)"
  type        = string
  default     = "web-bd"
}

variable "web_bd_description" {
  description = "Web BD 설명"
  type        = string
  default     = "Bridge Domain for Web Tier"
}

variable "web_subnet_ip" {
  description = "Web Tier Subnet (게이트웨이 IP/prefix) — ACI BD Subnet은 GW IP를 설정"
  type        = string
  default     = "10.10.1.1/24"
}

variable "web_epg_name" {
  description = "Web Tier EPG 이름 (fvAEPg)"
  type        = string
  default     = "web-epg"
}

variable "web_epg_description" {
  description = "Web EPG 설명"
  type        = string
  default     = "EPG for Web Tier (Frontend)"
}

# -----------------------------------------------------------------------------
# App Tier BD / Subnet 설정
# ACI DN: uni/tn-<tenant>/BD-<bd_name>
# 역할: 미들웨어·애플리케이션 서버 계층 (비즈니스 로직)
# -----------------------------------------------------------------------------
variable "app_bd_name" {
  description = "App Tier Bridge Domain 이름 (fvBD)"
  type        = string
  default     = "app-bd"
}

variable "app_bd_description" {
  description = "App BD 설명"
  type        = string
  default     = "Bridge Domain for App Tier"
}

variable "app_subnet_ip" {
  description = "App Tier Subnet (게이트웨이 IP/prefix)"
  type        = string
  default     = "10.10.2.1/24"
}

variable "app_epg_name" {
  description = "App Tier EPG 이름 (fvAEPg)"
  type        = string
  default     = "app-epg"
}

variable "app_epg_description" {
  description = "App EPG 설명"
  type        = string
  default     = "EPG for App Tier (Business Logic)"
}

# -----------------------------------------------------------------------------
# DB Tier BD / Subnet 설정
# ACI DN: uni/tn-<tenant>/BD-<bd_name>
# 역할: 데이터베이스 계층 (데이터 저장·조회)
# -----------------------------------------------------------------------------
variable "db_bd_name" {
  description = "DB Tier Bridge Domain 이름 (fvBD)"
  type        = string
  default     = "db-bd"
}

variable "db_bd_description" {
  description = "DB BD 설명"
  type        = string
  default     = "Bridge Domain for DB Tier"
}

variable "db_subnet_ip" {
  description = "DB Tier Subnet (게이트웨이 IP/prefix)"
  type        = string
  default     = "10.10.3.1/24"
}

variable "db_epg_name" {
  description = "DB Tier EPG 이름 (fvAEPg)"
  type        = string
  default     = "db-epg"
}

variable "db_epg_description" {
  description = "DB EPG 설명"
  type        = string
  default     = "EPG for DB Tier (Database)"
}

# -----------------------------------------------------------------------------
# Contract: Web → App (HTTP 8080)
# ACI DN: uni/tn-<tenant>/brc-<contract_name>
# 트래픽 흐름: web-epg(Consumer) → app-epg(Provider) on TCP 8080
# -----------------------------------------------------------------------------
variable "web_to_app_contract_name" {
  description = "Web→App Contract 이름 (vzBrCP)"
  type        = string
  default     = "allow-web-to-app"
}

variable "web_to_app_contract_description" {
  description = "Web→App Contract 설명"
  type        = string
  default     = "Allow HTTP 8080 from Web Tier to App Tier"
}

variable "web_to_app_filter_name" {
  description = "Web→App Filter 이름 (vzFilter)"
  type        = string
  default     = "filter-web-app"
}

variable "web_to_app_filter_description" {
  description = "Web→App Filter 설명"
  type        = string
  default     = "Filter for Web-to-App traffic"
}

variable "web_to_app_port" {
  description = "Web→App 허용 포트 (App 서버 포트, 기본 8080)"
  type        = string
  default     = "8080"
}

# -----------------------------------------------------------------------------
# Contract: App → DB (MySQL 3306)
# ACI DN: uni/tn-<tenant>/brc-<contract_name>
# 트래픽 흐름: app-epg(Consumer) → db-epg(Provider) on TCP 3306
# -----------------------------------------------------------------------------
variable "app_to_db_contract_name" {
  description = "App→DB Contract 이름 (vzBrCP)"
  type        = string
  default     = "allow-app-to-db"
}

variable "app_to_db_contract_description" {
  description = "App→DB Contract 설명"
  type        = string
  default     = "Allow MySQL 3306 from App Tier to DB Tier"
}

variable "app_to_db_filter_name" {
  description = "App→DB Filter 이름 (vzFilter)"
  type        = string
  default     = "filter-app-db"
}

variable "app_to_db_filter_description" {
  description = "App→DB Filter 설명"
  type        = string
  default     = "Filter for App-to-DB traffic"
}

variable "app_to_db_port" {
  description = "App→DB 허용 포트 (MySQL 포트, 기본 3306)"
  type        = string
  default     = "3306"
}