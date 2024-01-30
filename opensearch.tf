#Create an Organiztion
resource "aiven_organization" "sampleorg" {
  name = "The Company"
}

#Create a project for that Org
resource "aiven_project" "zimp_sample_project" {
  project    = "zim-demo"
  parent_id = aiven_organization.sampleorg.id
}

#Creat an Admin Team
resource "aiven_account_team" "tm-admin" {
  account_id = aiven_organization.sampleorg.id
  name       = "Admins"
}

#Grant the team admin Access to your project
resource "aiven_account_team_project" "rbac-prod-admin" {
  account_id   = aiven_organization.sampleorg.id
  team_id      = aiven_account_team.tm-admin.team_id
  project_name = aiven_project.zimp_sample_project.project
  team_type    = "admin"
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

#Kafka Service
resource "aiven_kafka" "kafka1" {
  project                 = aiven_project.zimp_sample_project.project
  cloud_name              = var.cloud_region
  plan                    = "business-4"
  service_name            = "kafka-demo"
  maintenance_window_dow  = "monday"
  maintenance_window_time = "10:00:00"
  project_vpc_id          = aiven_project_vpc.googlevpc.id

  kafka_user_config {
    kafka_rest      = true
    kafka_connect   = true
    schema_registry = true
    kafka_version   = "3.1"

    kafka {
      group_max_session_timeout_ms = 70000
      log_retention_bytes          = 1000000000
    }

    public_access {
      kafka_rest    = true
      kafka_connect = true
    }
  }
}