# =============================================================================
# Scenario 01 — Basic Tenant
# 파일: versions.tf
# 역할: Terraform 버전과 Provider를 고정한다
#
# 왜 versions.tf를 별도 파일로 분리하는가?
#   - Terraform 커뮤니티 관행: Provider 설정과 리소스 정의를 분리
#   - 팀 협업 시 버전 불일치 문제를 조기에 차단
#   - CI/CD 파이프라인에서 버전 검증 기준점 역할
# =============================================================================


terraform {
  # required_version: 이 코드를 실행할 수 있는 Terraform CLI 최소 버전 지정
  # ">= 1.7.0" → 1.7.0 이상만 허용 (이하 버전에서 실행 시 즉시 오류)
  required_version = ">= 1.7.0"

  required_providers {
    aci = {
      # source: Provider를 다운로드할 레지스트리 경로
      # "CiscoDevNet/aci" → registry.terraform.io/CiscoDevNet/aci
      # Cisco가 공식 배포하는 ACI Provider
      source = "CiscoDevNet/aci"

      # version: 허용할 Provider 버전 범위
      # "~> 2.13" → 2.13.x 허용, 2.14 이상은 차단 (Pessimistic Constraint)
      # 이유: Minor 버전 업그레이드 시 breaking change가 발생할 수 있으므로
      #       안정성을 위해 Patch 버전 업데이트만 허용
      version = "~> 2.13"
    }
  }
}


# -----------------------------------------------------------------------------
# Provider 설정: aci
# 역할: APIC 접속 정보를 설정한다
#
# 모든 변수값은 terraform.tfvars에서 주입 (크리덴셜 하드코딩 금지)
# -----------------------------------------------------------------------------
provider "aci" {
  # username / password: APIC 로그인 계정
  # variables.tf에서 password는 sensitive = true로 정의
  # → terraform plan/apply 출력에서 값이 자동 마스킹됨
  username = var.aci_username
  password = var.aci_password

  # url: APIC 접속 URL
  # 형식: "https://{APIC_IP_또는_hostname}"
  url = var.aci_url

  # insecure: TLS 인증서 검증 비활성화
  # true  → 자체 서명 인증서 허용 (Sandbox / 개발 환경)
  # false → 공인 인증서 필수 (운영 환경 권장)
  insecure = var.aci_insecure
}

