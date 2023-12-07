terraform {
  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = "4.9.3"
    }
  }
}

provider "aiven" {
  api_token = var.aiven_api_token
}
