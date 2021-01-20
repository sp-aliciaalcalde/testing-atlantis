###############################################
# Datadog Monitoring Stack
###############################################

#################
# Providers
#################
data "aws_secretsmanager_secret" "datadog_keys" {
  arn = var.datadog_keys
}
data "aws_secretsmanager_secret_version" "datadog_keys_latest" {
  secret_id = data.aws_secretsmanager_secret.datadog_keys.id
}
#################
# Providers
#################

terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "devops-ops-admin"
}

provider "datadog" {
  api_key = jsondecode(data.aws_secretsmanager_secret_version.datadog_keys_latest.secret_string)["api_key"]
  app_key = jsondecode(data.aws_secretsmanager_secret_version.datadog_keys_latest.secret_string)["app_key"]
  api_url = var.datadog_url
}

#################
# TF Modules
#################

module "datadog_monitor" {
  source     = "../../modules/datadog/datadog_monitor"
  for_each   = local.datadog_monitor
  name       = each.value.name
  type       = local.datadog_monitor[each.key].type
  message    = "${local.datadog_monitor[each.key].message} ${var.slack_notification}"
  query      = local.datadog_monitor[each.key].query
  thresholds = local.datadog_monitor[each.key].thresholds
  tags       = local.datadog_monitor[each.key].tags
}
