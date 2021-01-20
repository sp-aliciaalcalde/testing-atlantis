terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

resource "datadog_monitor" "monitor" {
  count   = var.monitor_enabled ? 1 : 0
  name    = var.name
  type    = var.type
  message = var.message

  query = var.query

  thresholds = var.thresholds

  notify_no_data    = var.notify_no_data
  renotify_interval = var.renotify_interval

  # ignore any changes in silenced value; using silenced is deprecated in favor of downtimes
  lifecycle {
    ignore_changes = [silenced]
  }

  tags = var.tags
}

