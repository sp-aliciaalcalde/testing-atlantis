output "monitor_ids" { value = join(",", datadog_monitor.monitor.*.id) }
