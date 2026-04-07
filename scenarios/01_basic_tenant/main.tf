# =============================================================================
# Scenario 01 — Basic Tenant
# 파일: main.tf
# 역할: 4개 모듈을 호출하여 ACI 오브젝트 전체를 프로비저닝한다
#
# 모듈 호출 순서 (Terraform 의존성 그래프가 자동 결정):
#   1. module.tenant     → Tenant + VRF 생성
#                          (다른 모든 모듈의 기반이 되므로 가장 먼저 생성)
#   2. module.policy     → Filter + Contract 생성
#                          (EPG 바인딩 전에 Contract가 존재해야 함)
#   3. module.networking → BD + Subnet 생성
#                          (EPG가 BD를 참조하므로 BD가 먼저 존재해야 함)
#   4. module.epg        → AP + EPG + Contract 바인딩
#                          (위 3개 모듈 결과를 모두 참조하므로 마지막)
#
# 모듈 간 데이터 흐름:
#   tenant.tenant_dn → policy.tenant_dn
#   tenant.tenant_dn → networking.tenant_dn
#   tenant.tenant_dn → epg.tenant_dn
#   tenant.vrf_dn    → networking.vrf_dn
#   networking.bd_dn → epg.bd_dn
#   policy.contract_dn → epg.contracts[].contract_dn
# =============================================================================


# -----------------------------------------------------------------------------
# 모듈 1: tenant
# 생성 오브젝트: Tenant(fvTenant) + VRF(fvCtx)
# -----------------------------------------------------------------------------
module "tenant" {
  # source: 이 모듈의 코드가 있는 경로
  # 상대경로: scenarios/01_basic_tenant/ 기준으로 두 단계 위 → terraform/modules/tenant
  source = "../../terraform/modules/tenant"

  tenant_name        = var.tenant_name
  tenant_description = var.tenant_description
  vrf_name           = var.vrf_name
  vrf_description    = var.vrf_description
  # vrf_enforcement 생략 → modules/tenant/variables.tf의 default("enforced") 사용
}


# -----------------------------------------------------------------------------
# 모듈 2: policy
# 생성 오브젝트: Filter(vzFilter) + Entry(vzEntry) + Contract(vzBrCP) + Subject(vzSubj)
# 의존성: tenant_dn이 필요하므로 module.tenant 완료 후 실행
# -----------------------------------------------------------------------------
module "policy" {
  source = "../../terraform/modules/policy"

  # module.tenant.tenant_dn: module.tenant의 output.tenant_dn 값을 참조
  # Terraform이 이 참조를 감지하여 module.tenant → module.policy 실행 순서를 자동 보장
  tenant_dn = module.tenant.tenant_dn

  contract_name        = var.contract_name
  contract_description = var.contract_description
  contract_scope       = var.contract_scope
  subject_name         = var.subject_name
  subject_description  = "HTTP/HTTPS Subject"

  # filters: Filter와 Entry를 인라인으로 정의
  # 이 값은 policy 모듈의 variable.filters (map(object(...)))에 전달됨
  filters = {
    # "filter-http": Filter 이름 (맵의 키 = ACI Filter 오브젝트 이름)
    "filter-http" = {
      description = "HTTP and HTTPS Filter"
      entries = [
        {
          name        = "tcp-80"
          ether_t     = "ip"   # IPv4 트래픽
          ip_proto    = "tcp"  # TCP 프로토콜
          d_from_port = "http" # Named port: 80
          d_to_port   = "http" # 단일 포트이므로 from = to
          description = "Allow TCP port 80 (HTTP)"
        },
        {
          name        = "tcp-443"
          ether_t     = "ip"
          ip_proto    = "tcp"
          d_from_port = "https" # Named port: 443
          d_to_port   = "https"
          description = "Allow TCP port 443 (HTTPS)"
        }
      ]
    }
  }
}


# -----------------------------------------------------------------------------
# 모듈 3: networking
# 생성 오브젝트: Bridge Domain(fvBD) + Subnet(fvSubnet)
# 의존성: tenant_dn + vrf_dn 필요 → module.tenant 완료 후 실행
# -----------------------------------------------------------------------------
module "networking" {
  source = "../../terraform/modules/networking"

  tenant_dn = module.tenant.tenant_dn
  vrf_dn    = module.tenant.vrf_dn # BD를 VRF에 연결

  bd_name        = var.bd_name
  bd_description = var.bd_description
  subnets        = var.bd_subnets
  # unicast_route / arp_flood 생략 → 모듈 default 사용 (yes / no)
}


# -----------------------------------------------------------------------------
# 모듈 4: epg
# 생성 오브젝트: AP(fvAp) + EPG(fvAEPg) + Contract 바인딩
# 의존성: tenant_dn + bd_dn + contract_dn 모두 필요 → 3개 모듈 완료 후 실행
# -----------------------------------------------------------------------------
module "epg" {
  source = "../../terraform/modules/epg"

  tenant_dn = module.tenant.tenant_dn
  bd_dn     = module.networking.bd_dn # EPG를 BD에 연결

  ap_name         = var.ap_name
  ap_description  = var.ap_description
  epg_name        = var.epg_name
  epg_description = var.epg_description

  # contracts: EPG에 바인딩할 Contract 목록
  # web-epg는 allow-http Contract의 Provider이자 Consumer로 설정
  #   Provider: 외부에서 HTTP/HTTPS로 web-epg에 접근 허용
  #   Consumer: web-epg 자신도 Contract 규칙의 적용을 받음
  # (단일 EPG 시나리오 — Scenario 02에서 Provider/Consumer가 분리됨)
  contracts = [
    {
      contract_dn   = module.policy.contract_dn # policy 모듈 output 참조
      contract_type = "provider"
    },
    {
      contract_dn   = module.policy.contract_dn
      contract_type = "consumer"
    }
  ]

  # depends_on: 명시적 의존성 선언
  # module.policy.contract_dn을 이미 참조하고 있어 암묵적 의존성이 존재하지만
  # 모듈 간 참조에서 Terraform이 의존성을 놓치는 엣지케이스 방지를 위해 명시
  depends_on = [module.policy]
}
