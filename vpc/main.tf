
module "vpc" {
  source         = "../modules/vpc"
  count          = 1
  vpc_cidr_block = var.vpc_cidr_block
  account        = var.account
  environment    = var.environment
  region         = var.region
  region_short   = var.region_short
}

module "routing" {
  source = "../modules/routing-tables"
  count         = length(var.route_tables)
  iteration     = count.index
  vpc_id        = element(module.vpc[*].vpc_id, 0)
  igw_id        = element(module.vpc[*].igw_id, 0)
  network_names = var.network_names
  route_tables  = var.route_tables
  account       = var.account
  environment   = var.environment
  region        = var.region
  region_short  = var.region_short  
}

module "network" {
  source = "../modules/network"
  count         = length(var.availability_zones)
  vpc_id        = element(module.vpc[*].vpc_id, 0)
  igw_id        = element(module.vpc[*].igw_id, 0)
  az            = var.availability_zones[count.index]
  iteration     = count.index
  network_names = var.network_names
  network_cidrs = var.network_cidrs
  tables        = module.routing[*].table_id
  route_tables  = var.route_tables
  account       = var.account
  environment   = var.environment
  region        = var.region
  region_short  = var.region_short
}

# TODO: Create a Routing Module
# Route53 hosted zone
# Route53 DNS records
# Route53 zone association
