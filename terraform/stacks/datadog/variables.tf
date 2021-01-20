#Global
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}
#Datadog Provider
variable "datadog_keys" {
  description = "Datadog keys stored in AWS secret manager"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-1:202016285298:secret:all/externalservices/datadog-8UHcgX"
}
variable "datadog_url" {
  description = "Datadog URL provider"
  type        = string
  default     = "https://api.datadoghq.eu/"
}
variable "slack_notification" {
  description = "Slack monitoring channel notifications"
  type        = string
  default     = "@slack-datadog_alarms"
}

