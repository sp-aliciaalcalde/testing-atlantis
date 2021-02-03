# WORKSPACE VARS
locals {
  context_variables = {
    dev = {
      vpc_cidr = "10.100.0.0/16"
      aws_assume_role = "arn:aws:iam::203885735085:role/dev-smart-delegated-admin"
    }
  }
}

locals {
  workspaces     = merge(local.context_variables)
  workspace      = merge(local.workspaces[terraform.workspace])
  tags           = merge(var.tags, map("project", var.project), map("environment", terraform.workspace))
  name_prefix    = "testing-atlantis-1-${terraform.workspace}-${var.project}"
  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_cidrs   = [cidrsubnet(local.workspace["vpc_cidr"], 8, 1), cidrsubnet(local.workspace["vpc_cidr"], 8, 2)]
  private_cidrs  = concat([cidrsubnet(local.workspace["vpc_cidr"], 8, 11), cidrsubnet(local.workspace["vpc_cidr"], 8, 12)], local.lambda_cidrs)
  lambda_cidrs   = [cidrsubnet(local.workspace["vpc_cidr"], 3, 1), cidrsubnet(local.workspace["vpc_cidr"], 3, 2)]
  database_cidrs = [cidrsubnet(local.workspace["vpc_cidr"], 8, 21), cidrsubnet(local.workspace["vpc_cidr"], 8, 22)]
}
