variable "aiven_api_token" {
  description = "Aiven console API token"
  type        = string
}

variable "project_name" {
  description = "Aiven console project name"
  type        = string
}

variable "cloud_region" {
  description = "Cloud Region for primary OpenSearch cluster"
  type = string
}

variable "external_account_id" {
  description = "Account ID for GCP, used to peer VPCs"
  type = string
}

variable "external_vpc_id" {
  description = "Google VPC to peer Aiven services to"
  type = string
}