locals {

  common_tags = ["terraform"]
  tags_ec2    = ["docker", "ec2"]
  tags_rds    = ["rds"]
  tags_web    = ["urls_web"]


  datadog_monitor = {
    "ec2_cpu" = {
      name    = "EC2 | CPU Idle (percent)",
      type    = "metric alert",
      message = "[EC2] CPU Idle (percent)",
      query   = "avg(last_5m):avg:system.cpu.idle{region:eu-central-1} by {host} < 10",
      thresholds = {
        critical          = 10
        critical_recovery = 15
        warning           = 20
        warning_recovery  = 25
      }
      tags = concat(["cpu"], local.common_tags, local.tags_ec2)
    },
    "ec2_disk" = {
      name    = "EC2 | Disk free (fractions)",
      type    = "metric alert",
      message = "[EC2] Disk free (fractions)",
      query   = "avg(last_5m):avg:system.disk.in_use{region:eu-central-1,!device_name:loop0,!device_name:loop1,!device_name:loop2,!device_name:loop3,!device_name:loop4,!device_name:loop5,!device_name:loop6,!device_name:loop7,!device_name:loop8,!device_name:loop9,!device_name:loop10,!device_name:tmpfs,!device_name:udev,!device_name:nvme0n1p1} by {host,device_name} > 0.9",
      thresholds = {
        critical          = 0.9
        critical_recovery = 0.85
        warning           = 0.8
        warning_recovery  = 0.75
      }
      tags = concat(["disk"], local.common_tags, local.tags_ec2)
    },

    "ec2_docker_up" = {
      name    = "EC2 | Docker daemon up",
      type    = "service check",
      message = "[EC2] Docker daemon up",
      query   = "'process.up'.over('region:eu-central-1','process:docker').by('host','process').last(2).count_by_status()"
      thresholds = {
        "ok" : "1"
      }
      tags = concat(["docker_up"], local.common_tags, local.tags_ec2)
    },
    "ec2_memory_available" = {
      name    = "EC2 | Memory Available (Free + Cached) (fractions)",
      type    = "metric alert",
      message = "[EC2] Memory Available (Free + Cached) (fractions)",
      query   = "avg(last_5m):(avg:system.mem.free{region:eu-central-1} by {host} + avg:system.mem.cached{region:eu-central-1} by {host} ) / avg:system.mem.total{region:eu-central-1} by {host} < 0.1"
      thresholds = {
        critical          = 0.1
        critical_recovery = 0.15
        warning           = 0.2
        warning_recovery  = 0.25
      }
      tags = concat(["memory_available"], local.common_tags, local.tags_ec2)
    },

    "ec2_memory_free" = {
      name    = "EC2 | Memory Free (fractions)",
      type    = "metric alert",
      message = "[EC2] Memory Free (fractions)",
      query   = "avg(last_5m):avg:system.mem.free{region:eu-central-1} by {host} / avg:system.mem.total{region:eu-central-1} by {host} < 0.1"
      thresholds = {
        critical          = 0.1
        critical_recovery = 0.15
        warning           = 0.2
        warning_recovery  = 0.25
      }
      tags = concat(["memory_free"], local.common_tags, local.tags_ec2)
    },
    "ec2_uptime" = {
      name    = "EC2 | Uptime (seconds)",
      type    = "metric alert",
      message = "[EC2] Uptime (seconds)",
      query   = "avg(last_5m):avg:system.uptime{region:eu-central-1} by {host} < 0.1"
      thresholds = {
        critical          = 0.1
        critical_recovery = 0.15
        warning           = 0.2
        warning_recovery  = 0.25
      }
      tags = ["uptime", "docker", "ec2", "terraform"]
    },
    "rds_cpu" = {
      name    = "RDS | CPU Idle (percent)",
      type    = "metric alert",
      message = "[RDS] CPU Idle (percent)",
      query   = " avg(last_5m):avg:aws.rds.cpuutilization{region:eu-central-1} by {dbinstanceidentifier} > 90",
      thresholds = {
        critical          = 90
        critical_recovery = 85
        warning           = 80
        warning_recovery  = 75
      }
      tags = concat(["cpu"], local.common_tags, local.tags_rds)
    },
    "rds_disk" = {
      name    = "RDS | Storage free (GB)",
      type    = "metric alert",
      message = "[RDS] Storage available (GB)",
      query   = "avg(last_5m):avg:aws.rds.free_storage_space{region:eu-central-1} by {host} / avg:aws.rds.total_storage_space{region:eu-central-1} * 1048576 <1",
      thresholds = {
        critical          = 1
        critical_recovery = 1.5
        warning           = 2
        warning_recovery  = 2.5
      }
      tags = concat(["disk"], local.common_tags, local.tags_rds)
    },
    "rds_memory" = {
      name    = "RDS | Memory Free (fractions)",
      type    = "metric alert",
      message = "[RDS] Memory Free (fractions)",
      query   = "avg(last_5m):avg:aws.rds.freeable_memory{region:eu-central-1} by {dbinstanceidentifier} < 0.8",
      thresholds = {
        critical          = 0.8
        critical_recovery = 0.9
        warning           = 1
        warning_recovery  = 1.5
      }
      tags = concat(["memory"], local.common_tags, local.tags_rds)
    },
    "rds_replica_lag" = {
      name    = "RDS | Read Replica lag (seconds)",
      type    = "metric alert",
      message = " [ RDS ] | Memory Free (fractions)",
      query   = "avg(last_5m):avg:aws.rds.replica_lag{region:eu-central-1} by {dbinstanceidentifier} >60",
      thresholds = {
        critical          = 60
        critical_recovery = 55
        warning           = 30
        warning_recovery  = 25
      }
      tags = concat(["replica_lag"], local.common_tags, local.tags_rds)
    }
    "http_url" = {
      name    = "URLs | Available",
      type    = "metric alert",
      message = " [ URLs ] | Available",
      query   = "avg(last_5m):avg:network.http.can_connect{url:https://smartprotection.com/es/} by {url} + avg:network.http.can_connect{url:http://www.3ants.com/} by {url} + avg:network.http.can_connect{url:https://ws.smartbrandprotection.com/login} by {url} + avg:network.http.can_connect{url:https://live-event.smartmediaprotection.com/login} by {url} + avg:network.http.can_connect{url:https://ws.smartmediaprotection.com/login} by {url} + avg:network.http.can_connect{url:https://ws.smartpublishingprotection.com/login} by {url} + avg:network.http.can_connect{url:https://brand.3antsds.com/} by {url} + avg:network.http.can_connect{url:https://media.3antsds.com/} by {url} + avg:network.http.can_connect{url:https://publishing.3antsds.com/} by {url} + avg:network.http.can_connect{url:https://operations.3antsds.com/sesiones/login} by {url} + avg:network.http.can_connect{url:https://user-portal.smartbrandprotection.com/login/} by {url} + avg:network.http.can_connect{url:https://user-portal.smartmediaprotection.com/login/} by {url} + avg:network.http.can_connect{url:https://user-portal.smartpublishingprotection.com/login/} by {url} + avg:network.http.can_connect{url:https://shadow.smartmediaprotection.com/v1.1/tasks} by {url} + avg:network.http.can_connect{url:https://shadow.smartpublishingprotection.com/v1.1/tasks} by {url} + avg:network.http.can_connect{url:https://api-report.3antsds.com/healthcheck} by {url} + avg:network.http.can_connect{url:https://reports.smartbrandprotection.com/healthcheck} by {url} + avg:network.http.can_connect{url:https://reports.smartmediaprotection.com/healthcheck} by {url} + avg:network.http.can_connect{url:https://reports.smartpublishingprotection.com/healthcheck} by {url} <0",
      thresholds = {
        critical          = 0
        critical_recovery = 1
        warning           = 0.5
        warning_recovery  = 1
      }
      tags = concat(["web_url"], local.common_tags, local.tags_web)
    },
    "http_certificate" = {
      name    = "URLs | SSL Certicate Expired",
      type    = "metric alert",
      message = " [ URLs ] | SSL Certicate Expired",
      query   = "avg(last_5m):avg:http.ssl.days_left{url:https://smartprotection.com/es/} by {url} + avg:http.ssl.days_left{url:http://www.3ants.com/} by {url} + avg:http.ssl.days_left{url:https://ws.smartbrandprotection.com/login} by {url} + avg:http.ssl.days_left{url:https://live-event.smartmediaprotection.com/login} by {url} + avg:http.ssl.days_left{url:https://ws.smartmediaprotection.com/login} by {url} + avg:http.ssl.days_left{url:https://ws.smartpublishingprotection.com/login} by {url} + avg:http.ssl.days_left{url:https://brand.3antsds.com/} by {url} + avg:http.ssl.days_left{url:https://media.3antsds.com/} by {url} + avg:http.ssl.days_left{url:https://publishing.3antsds.com/} by {url} + avg:http.ssl.days_left{url:https://operations.3antsds.com/sesiones/login} by {url} + avg:http.ssl.days_left{url:https://user-portal.smartbrandprotection.com/login/} by {url} + avg:http.ssl.days_left{url:https://user-portal.smartmediaprotection.com/login/} by {url} + avg:http.ssl.days_left{url:https://user-portal.smartpublishingprotection.com/login/} by {url} + avg:http.ssl.days_left{url:https://shadow.smartmediaprotection.com/v1.1/tasks} by {url} + avg:http.ssl.days_left{url:https://shadow.smartpublishingprotection.com/v1.1/tasks} by {url} + avg:http.ssl.days_left{url:https://api-report.3antsds.com/healthcheck} by {url} + avg:http.ssl.days_left{url:https://reports.smartbrandprotection.com/healthcheck} by {url} + avg:http.ssl.days_left{url:https://reports.smartmediaprotection.com/healthcheck} by {url} + avg:http.ssl.days_left{url:https://reports.smartpublishingprotection.com/healthcheck} by {url} < 15",
      thresholds = {
        critical          = 15
        critical_recovery = 20
        warning           = 20
        warning_recovery  = 25
      }
      tags = concat(["web_url"], local.common_tags, local.tags_web)
    }
  }
}
