#Create an Organiztion
resource "aiven_organization" "sampleorg" {
  name = "The Company"
}

#Create a project for that Org
resource "aiven_project" "zimp_sample_project" {
  project    = "zimo-demo"
  parent_id = aiven_organization.sampleorg.id
}

#Create an Admin Team
resource "aiven_organization_user_group" "tm-admin" {
  organization_id = aiven_organization.sampleorg.id
  name            = "Admins"
  description     = "Administers all projects"
}

#Grant the team admin Access to your project
#This requires the PROVIDER_AIVEN_ENABLE_BETA environment variable to be set to "true"
resource "aiven_organization_group_project" "rbac-prod-admin" {
  group_id            = aiven_organization_user_group.tm-admin.id
  project             = aiven_project.zimp_sample_project.project
  role                = "admin"
}

#Datadog Endpoint
resource "aiven_service_integration_endpoint" "datadog" {
   project = aiven_project.zimp_sample_project.project
   endpoint_name="Datadog Metrics"
   endpoint_type="datadog"
    datadog_user_config {
        datadog_api_key = "xxxxxxxxxxx"
        datadog_tags {
          tag = "<Customer Name?>"
        }
        #site = "<Your Site Here if non-Standard>" # Datadog intake site. Defaults to datadoghq.com
    }
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

#Send OS metrics to Datadog
resource "aiven_service_integration" "datadog_os_metrics_int" {
    project = aiven_project.zimp_sample_project.project
    destination_endpoint_id = aiven_service_integration_endpoint.datadog.id
    destination_service_name = ""
    integration_type = "datadog"
    source_service_name = aiven_opensearch.os1.service_name
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

#Send Kafka Metrics to Datadog
resource "aiven_service_integration" "datadog_kafka_metrics_int" {
  project = aiven_project.zimp_sample_project.project
  destination_endpoint_id = aiven_service_integration_endpoint.datadog.id
  destination_service_name = ""
  integration_type = "datadog"
  source_service_name = aiven_kafka.kafka1.service_name
}

