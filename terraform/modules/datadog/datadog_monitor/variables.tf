variable "monitor_enabled" {
  description = "Enabled Datadog monitor metrics"
  type        = bool
  default     = true
}
variable "name" {
  description = "Datadog metric name"
  type        = string
  default     = ""
}
variable "type" {
  description = "Datadog metric type"
  type        = string
  default     = ""
}
variable "message" {
  description = "Datadog metric messages"
  type        = string
  default     = ""
}
variable "query" {
  description = "Datadog metric query"
  type        = string
  default     = ""
}
variable "thresholds" {
  description = "Datadog metric thresholds"
  type        = map(any)
  default     = {}
}
variable "notify_no_data" {
  description = "Datadog metric will notify when data stops reporting "
  type        = bool
  default     = true
}
variable "renotify_interval" {
  description = "The number of minutes after the last Datadog notification before a monitor will re-notify"
  type        = number
  default     = 60
}
variable "tags" {
  description = "Datadog metric tags associated"
  type        = list(any)
  default     = []
}
