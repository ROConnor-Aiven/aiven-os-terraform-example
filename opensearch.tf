resource "aiven_organization" "sampleorg" {
  name = "The Company"
}

resource "aiven_project" "zimp_sample_project" {
  project    = "zim-demo"
  parent_id = aiven_organization.sampleorg.id
}

#VPC
resource "aiven_project_vpc" "googlevpc" {
  project      = aiven_project.zimp_sample_project.project
  cloud_name   = var.cloud_region
  network_cidr = "192.168.1.0/24"


  timeouts {
    create = "5m"
  }
}

#Peer your Aiven VPC to your google VPC
resource "aiven_gcp_vpc_peering_connection" "gcp_peer" {
  vpc_id = aiven_project_vpc.googlevpc.id
  # this will be your Google cloud project ID and network ID
  gcp_project_id = var.external_account_id
  peer_vpc       = var.external_vpc_id
}


# Opensearch Service - https://registry.terraform.io/providers/aiven/aiven/latest/docs/resources/opensearch
resource "aiven_opensearch" "os1" {
  project                 = aiven_project.zimp_sample_project.project
  cloud_name              = var.cloud_region
  plan                    = "startup-4"
  service_name            = "os-demo"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"
  project_vpc_id          = aiven_project_vpc.googlevpc.id
  #additional_disk_space  = 
  #termination_protection = true #Set on production services to prevent accidental deletion.

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

