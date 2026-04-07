# =============================================================================
# main.tf — Scenario 02: Three-Tier App
# =============================================================================
# 구현 구조:
#   Tenant: three-tier
#     └── VRF: app-vrf  (tenant 모듈이 생성)
#         ├── BD: web-bd (10.10.1.0/24) → EPG: web-epg
#         ├── BD: app-bd (10.10.2.0/24) → EPG: app-epg
#         └── BD: db-bd  (10.10.3.0/24) → EPG: db-epg
#
# Contract 흐름:
#   web-epg(Consumer) → allow-web-to-app → app-epg(Provider) : TCP 8080
#   app-epg(Consumer) → allow-app-to-db  → db-epg(Provider)  : TCP 3306
#
# 모듈 인터페이스 원칙:
#   - networking 모듈: vrf_dn을 직접 전달 (VRF는 tenant 모듈이 생성)
#   - policy 모듈: filters 맵 방식 사용 (기존 모듈 변수 그대로)
#   - epg 모듈: create_ap 플래그 사용 (이번에 추가된 변수)
# =============================================================================


# =============================================================================
# MODULE 1: Tenant + VRF
# =============================================================================
# VRF는 tenant 모듈에서 생성 → module.tenant.vrf_dn으로 세 BD 모두 공유
# DN:
#   Tenant: uni/tn-three-tier
#   VRF:    uni/tn-three-tier/ctx-app-vrf
# =============================================================================
module "tenant" {
  source = "../../terraform/modules/tenant"

  tenant_name        = var.tenant_name
  tenant_description = var.tenant_description
  vrf_name           = var.vrf_name
  vrf_description    = var.vrf_description
  # vrf_enforcement 생략 → 모듈 default ("enforced") 사용
}


# =============================================================================
# MODULE 2a: Web Tier — Bridge Domain + Subnet
# =============================================================================
# vrf_dn: module.tenant.vrf_dn 전달 (세 BD 모두 동일한 VRF 사용)
# subnets: list(object) 형식 → networking 모듈 기존 인터페이스
# DN:
#   BD:     uni/tn-three-tier/BD-web-bd
#   Subnet: uni/tn-three-tier/BD-web-bd/subnet-[10.10.1.1/24]
# =============================================================================
module "web_networking" {
  source = "../../terraform/modules/networking"

  tenant_dn = module.tenant.tenant_dn
  vrf_dn    = module.tenant.vrf_dn

  bd_name        = var.web_bd_name
  bd_description = var.web_bd_description

  subnets = [
    {
      ip          = var.web_subnet_ip
      scope       = ["private"]
      description = "Web Tier Gateway"
    }
  ]
}


# =============================================================================
# MODULE 2b: App Tier — Bridge Domain + Subnet
# =============================================================================
# DN:
#   BD:     uni/tn-three-tier/BD-app-bd
#   Subnet: uni/tn-three-tier/BD-app-bd/subnet-[10.10.2.1/24]
# =============================================================================
module "app_networking" {
  source = "../../terraform/modules/networking"

  tenant_dn = module.tenant.tenant_dn
  vrf_dn    = module.tenant.vrf_dn    # Web과 동일한 VRF

  bd_name        = var.app_bd_name
  bd_description = var.app_bd_description

  subnets = [
    {
      ip          = var.app_subnet_ip
      scope       = ["private"]
      description = "App Tier Gateway"
    }
  ]
}


# =============================================================================
# MODULE 2c: DB Tier — Bridge Domain + Subnet
# =============================================================================
# DN:
#   BD:     uni/tn-three-tier/BD-db-bd
#   Subnet: uni/tn-three-tier/BD-db-bd/subnet-[10.10.3.1/24]
# =============================================================================
module "db_networking" {
  source = "../../terraform/modules/networking"

  tenant_dn = module.tenant.tenant_dn
  vrf_dn    = module.tenant.vrf_dn    # Web/App과 동일한 VRF

  bd_name        = var.db_bd_name
  bd_description = var.db_bd_description

  subnets = [
    {
      ip          = var.db_subnet_ip
      scope       = ["private"]
      description = "DB Tier Gateway"
    }
  ]
}


# =============================================================================
# MODULE 3a: Policy — Web→App Contract (TCP 8080)
# =============================================================================
# filters: map(object) 형식 → policy 모듈 기존 인터페이스
# 키: filter 이름, 값: { description, entries[] }
# DN:
#   Contract: uni/tn-three-tier/brc-allow-web-to-app
#   Filter:   uni/tn-three-tier/flt-filter-web-app
#   Entry:    uni/tn-three-tier/flt-filter-web-app/e-tcp-8080
# =============================================================================
module "web_to_app_policy" {
  source = "../../terraform/modules/policy"

  tenant_dn = module.tenant.tenant_dn

  contract_name        = var.web_to_app_contract_name
  contract_description = var.web_to_app_contract_description
  contract_scope       = "tenant"

  subject_name        = "web-app-subj"
  subject_description = "Subject for Web to App traffic"

  # filters: policy 모듈의 variable.filters 타입에 맞게 맵 형식으로 전달
  filters = {
    (var.web_to_app_filter_name) = {
      description = var.web_to_app_filter_description
      entries = [
        {
          name        = "tcp-8080"
          ether_t     = "ip"
          ip_proto    = "tcp"       # policy/main.tf 내부에서 prot 속성으로 매핑됨
          d_from_port = var.web_to_app_port
          d_to_port   = var.web_to_app_port
          description = "Allow TCP 8080 (App Server)"
        }
      ]
    }
  }
}


# =============================================================================
# MODULE 3b: Policy — App→DB Contract (TCP 3306)
# =============================================================================
# DN:
#   Contract: uni/tn-three-tier/brc-allow-app-to-db
#   Filter:   uni/tn-three-tier/flt-filter-app-db
#   Entry:    uni/tn-three-tier/flt-filter-app-db/e-tcp-3306
# =============================================================================
module "app_to_db_policy" {
  source = "../../terraform/modules/policy"

  tenant_dn = module.tenant.tenant_dn

  contract_name        = var.app_to_db_contract_name
  contract_description = var.app_to_db_contract_description
  contract_scope       = "tenant"

  subject_name        = "app-db-subj"
  subject_description = "Subject for App to DB traffic"

  filters = {
    (var.app_to_db_filter_name) = {
      description = var.app_to_db_filter_description
      entries = [
        {
          name        = "tcp-3306"
          ether_t     = "ip"
          ip_proto    = "tcp"
          d_from_port = var.app_to_db_port
          d_to_port   = var.app_to_db_port
          description = "Allow TCP 3306 (MySQL)"
        }
      ]
    }
  }
}


# =============================================================================
# MODULE 4a: Web Tier EPG
# =============================================================================
# create_ap = true → AP(three-tier-ap)를 이 모듈에서 생성
# contracts: web-epg는 allow-web-to-app의 Consumer
# DN:
#   AP:  uni/tn-three-tier/ap-three-tier-ap
#   EPG: uni/tn-three-tier/ap-three-tier-ap/epg-web-epg
# =============================================================================
module "web_epg" {
  source = "../../terraform/modules/epg"

  tenant_dn      = module.tenant.tenant_dn
  bd_dn          = module.web_networking.bd_dn

  create_ap      = true
  ap_name        = var.ap_name
  ap_description = var.ap_description

  epg_name        = var.web_epg_name
  epg_description = var.web_epg_description

  contracts = [
    {
      contract_dn   = module.web_to_app_policy.contract_dn
      contract_type = "consumer"
    }
  ]

  depends_on = [module.web_networking, module.web_to_app_policy]
}


# =============================================================================
# MODULE 4b: App Tier EPG
# =============================================================================
# create_ap = false → module.web_epg.ap_dn 참조
# contracts:
#   allow-web-to-app → provider (web에게 서비스 제공)
#   allow-app-to-db  → consumer (db에게 요청 발신)
# DN:
#   EPG: uni/tn-three-tier/ap-three-tier-ap/epg-app-epg
# =============================================================================
module "app_epg" {
  source = "../../terraform/modules/epg"

  tenant_dn      = module.tenant.tenant_dn
  bd_dn          = module.app_networking.bd_dn

  create_ap      = false
  ap_name        = var.ap_name
  existing_ap_dn = module.web_epg.ap_dn

  epg_name        = var.app_epg_name
  epg_description = var.app_epg_description

  contracts = [
    {
      contract_dn   = module.web_to_app_policy.contract_dn
      contract_type = "provider"
    },
    {
      contract_dn   = module.app_to_db_policy.contract_dn
      contract_type = "consumer"
    }
  ]

  depends_on = [module.web_epg, module.app_networking, module.web_to_app_policy, module.app_to_db_policy]
}


# =============================================================================
# MODULE 4c: DB Tier EPG
# =============================================================================
# create_ap = false → module.web_epg.ap_dn 참조
# contracts:
#   allow-app-to-db → provider (app에게 DB 서비스 제공)
# DN:
#   EPG: uni/tn-three-tier/ap-three-tier-ap/epg-db-epg
# =============================================================================
module "db_epg" {
  source = "../../terraform/modules/epg"

  tenant_dn      = module.tenant.tenant_dn
  bd_dn          = module.db_networking.bd_dn

  create_ap      = false
  ap_name        = var.ap_name
  existing_ap_dn = module.web_epg.ap_dn

  epg_name        = var.db_epg_name
  epg_description = var.db_epg_description

  contracts = [
    {
      contract_dn   = module.app_to_db_policy.contract_dn
      contract_type = "provider"
    }
  ]

  depends_on = [module.web_epg, module.db_networking, module.app_to_db_policy]
}