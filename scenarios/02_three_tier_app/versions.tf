# =============================================================================
# versions.tf — Scenario 02: Three-Tier App
# =============================================================================
# 목적: Provider 버전 고정
# Terraform 버전과 CiscoDevNet/aci Provider 버전을 명시적으로 고정하여
# 팀원·CI 환경에서 동일한 동작을 보장한다.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = "~> 2.18.0"
    }
  }
}

# -----------------------------------------------------------------------------
# ACI Provider 설정
# -----------------------------------------------------------------------------
# 인증 정보는 terraform.tfvars에서 주입 (하드코딩 절대 금지)
# allow_insecure = true → DevNet Sandbox 자체 서명 인증서 허용
# -----------------------------------------------------------------------------
provider "aci" {
  username = var.aci_username
  password = var.aci_password
  url      = var.aci_url
  insecure = true
}