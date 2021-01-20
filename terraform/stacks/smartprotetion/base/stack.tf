##########################################
# SP Base Stack
##########################################
#####################
# AWS Provider
#####################

# Main AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "smart-${terraform.workspace}-admin"
}

# Root AWS Provider
provider "aws" {
  region = var.aws_region
  alias  = "root"
}

# OPS AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "devops-ops-admin"
  alias   = "ops"
}

#####################
# Data
#####################

data "aws_availability_zones" "available" {
  state = "available"
}

#####################
# TF Modules
#####################

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name                 = local.name_prefix
  cidr                 = local.workspace["vpc_cidr"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs                    = local.azs
  enable_nat_gateway     = lookup(var.nat_gateway, "enable_nat_gateway", false)
  single_nat_gateway     = lookup(var.nat_gateway, "single_nat_gateway", false)
  one_nat_gateway_per_az = lookup(var.nat_gateway, "one_nat_gateway_per_az", false)

  public_subnets   = local.public_cidrs
  private_subnets  = local.private_cidrs
  database_subnets = local.database_cidrs

  enable_flow_log                      = lookup(var.flow_log, "enable_flow_log", false)
  flow_log_destination_type            = lookup(var.flow_log, "flow_log_destination_type", "cloud-watch-logs")
  create_flow_log_cloudwatch_iam_role  = lookup(var.flow_log, "create_flow_log_cloudwatch_iam_role", false)
  create_flow_log_cloudwatch_log_group = lookup(var.flow_log, "create_flow_log_cloudwatch_log_group", false)

  tags = local.tags
}

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  name = local.name_prefix

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = {
    capacity_provider = "FARGATE_SPOT"
  }

  tags = local.tags
}

#####################
# VPN Peering
#####################

resource "aws_vpc_peering_connection" "vpn_peering" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.peering.vpn.vpc_id
  peer_owner_id = local.peering.vpn.account_id
  peer_region   = local.peering.vpn.region
  auto_accept   = false

  tags = merge(local.tags, map("Name", "${local.name_prefix}-peering-with-vpn"), map("side", "requester"))
}

resource "aws_vpc_peering_connection_accepter" "vpn_peering_accept" {
  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn_peering.id
  auto_accept               = true

  tags = merge(local.tags, map("Name", "vpn-peering-with-${local.name_prefix}"), map("side", "accepter"))
}

resource "aws_route" "vpn_peering_route" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = local.peering.vpn.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn_peering.id
}

resource "aws_ec2_client_vpn_route" "client_vpn_route" {
  provider               = aws.root
  description            = local.name_prefix
  client_vpn_endpoint_id = local.peering.vpn.client_vpn_endpoint_id
  destination_cidr_block = local.workspace["vpc_cidr"]
  target_vpc_subnet_id   = local.peering.vpn.client_vpn_target_subnet
}

resource "aws_vpc_peering_connection_options" "vpn_peering_connection_options" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.vpn_peering_accept.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "vpn_accepter_peering_connection_options" {
  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.vpn_peering_accept.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#####################
# OPS Peering
#####################

resource "aws_vpc_peering_connection" "ops_peering" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.peering.ops.vpc_id
  peer_owner_id = local.peering.ops.account_id
  peer_region   = local.peering.ops.region
  auto_accept   = false

  tags = merge(local.tags, map("Name", "${local.name_prefix}-peering-with-ops"), map("side", "requester"))
}

resource "aws_vpc_peering_connection_accepter" "ops_peering_accept" {
  provider                  = aws.ops
  vpc_peering_connection_id = aws_vpc_peering_connection.ops_peering.id
  auto_accept               = true

  tags = merge(local.tags, map("Name", "ops-peering-with-${local.name_prefix}"), map("side", "accepter"))
}

resource "aws_route" "ops_peering_route" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = local.peering.ops.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.ops_peering.id
}

resource "aws_route" "ops_peering_accepter_route" {
  provider                  = aws.ops
  route_table_id            = local.peering.ops.private_route_table
  destination_cidr_block    = local.workspace["vpc_cidr"]
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.ops_peering_accept.id
}

resource "aws_vpc_peering_connection_options" "ops_peering_connection_options" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.ops_peering_accept.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "ops_accepter_peering_connection_options" {
  provider                  = aws.ops
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.ops_peering_accept.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#####################
# Legacy DB Peering
#####################

resource "aws_vpc_peering_connection" "legacy_db_peering" {
  count = local.workspace == "pro" ? 1 : 0

  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.peering.legacy_db.vpc_id
  peer_owner_id = local.peering.legacy_db.account_id
  peer_region   = local.peering.legacy_db.region
  auto_accept   = false

  tags = merge(local.tags, map("Name", "${local.name_prefix}-peering-with-legacy-db"), map("side", "requester"))
}

resource "aws_vpc_peering_connection_accepter" "legacy_db_peering_accept" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_db_peering.*.id
  auto_accept               = true

  tags = merge(local.tags, map("Name", "legacy-db-peering-with-${local.name_prefix}"), map("side", "accepter"))
}

resource "aws_route" "legacy_db_peering_route" {
  count = local.workspace == "pro" ? length(module.vpc.private_route_table_ids) : 0

  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = local.peering.legacy_db.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_db_peering.*.id
}

resource "aws_route" "legacy_db_peering_accepter_route" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  route_table_id            = local.peering.legacy_db.private_route_table
  destination_cidr_block    = local.workspace["vpc_cidr"]
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_db_peering_accept.*.id
}

resource "aws_vpc_peering_connection_options" "legacy_db_peering_connection_options" {
  count = local.workspace == "pro" ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_db_peering_accept.*.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "legacy_db_accepter_peering_connection_options" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_db_peering_accept.*.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#####################
# Legacy PRO Peering
#####################

resource "aws_vpc_peering_connection" "legacy_pro_peering" {
  count = local.workspace == "pro" ? 1 : 0

  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.peering.legacy_pro.vpc_id
  peer_owner_id = local.peering.legacy_pro.account_id
  peer_region   = local.peering.legacy_pro.region
  auto_accept   = false

  tags = merge(local.tags, map("Name", "${local.name_prefix}-peering-with-legacy-pro"), map("side", "requester"))
}

resource "aws_vpc_peering_connection_accepter" "legacy_pro_peering_accept" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_pro_peering.*.id
  auto_accept               = true

  tags = merge(local.tags, map("Name", "legacy-pro-peering-with-${local.name_prefix}"), map("side", "accepter"))
}

resource "aws_route" "legacy_pro_peering_route" {
  count = local.workspace == "pro" ? length(module.vpc.private_route_table_ids) : 0

  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = local.peering.legacy_pro.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_pro_peering.*.id
}

resource "aws_route" "legacy_pro_peering_accepter_route" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  route_table_id            = local.peering.legacy_pro.private_route_table
  destination_cidr_block    = local.workspace["vpc_cidr"]
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pro_peering_accept.*.id
}

resource "aws_vpc_peering_connection_options" "legacy_pro_peering_connection_options" {
  count = local.workspace == "pro" ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pro_peering_accept.*.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "legacy_pro_accepter_peering_connection_options" {
  count = local.workspace == "pro" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pro_peering_accept.*.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#####################
# Legacy PRE Peering
#####################

resource "aws_vpc_peering_connection" "legacy_pre_peering" {
  count = local.workspace == "stg" ? 1 : 0

  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.peering.legacy_pre.vpc_id
  peer_owner_id = local.peering.legacy_pre.account_id
  peer_region   = local.peering.legacy_pre.region
  auto_accept   = false

  tags = merge(local.tags, map("Name", "${local.name_prefix}-peering-with-legacy-pre"), map("side", "requester"))
}

resource "aws_vpc_peering_connection_accepter" "legacy_pre_peering_accept" {
  count = local.workspace == "stg" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_pre_peering.*.id
  auto_accept               = true

  tags = merge(local.tags, map("Name", "legacy-pre-peering-with-${local.name_prefix}"), map("side", "accepter"))
}

resource "aws_route" "legacy_pre_peering_route" {
  count = local.workspace == "stg" ? length(module.vpc.private_route_table_ids) : 0

  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = local.peering.legacy_pre.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.legacy_pre_peering.*.id
}

resource "aws_route" "legacy_pre_peering_accepter_route" {
  count = local.workspace == "stg" ? 1 : 0

  provider                  = aws.root
  route_table_id            = local.peering.legacy_pre.private_route_table
  destination_cidr_block    = local.workspace["vpc_cidr"]
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pre_peering_accept.*.id
}

resource "aws_vpc_peering_connection_options" "legacy_pre_peering_connection_options" {
  count = local.workspace == "stg" ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pre_peering_accept.*.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "legacy_pre_accepter_peering_connection_options" {
  count = local.workspace == "stg" ? 1 : 0

  provider                  = aws.root
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.legacy_pre_peering_accept.*.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
