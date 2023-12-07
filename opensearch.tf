
#Optional VPC
resource "aiven_project_vpc" "googlevpc" {
  project      = var.project_name
  cloud_name   = var.cloud_region
  network_cidr = "192.168.1.0/24"

  timeouts {
    create = "5m"
  }
}

# Opensearch Service - https://registry.terraform.io/providers/aiven/aiven/latest/docs/resources/opensearch
resource "aiven_opensearch" "os1" {
  project                 = var.project_name
  cloud_name              = var.cloud_region
  plan                    = "startup-4"
  service_name            = "os-demo"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"
  project_vpc_id          = aiven_project_vpc.googlevpc.id
  #additional_disk_space  = 

  opensearch_user_config {
    opensearch_version = 1

    opensearch_dashboards {
      enabled                    = true
      opensearch_request_timeout = 30000
    }

    public_access {
      opensearch            = true
      opensearch_dashboards = true
    }
  }
}

