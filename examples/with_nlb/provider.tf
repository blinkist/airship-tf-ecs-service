terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region                      = var.region
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  version                     = "~> 2.14"
}

variable "region" {
  ## Sorry I'm from this region
  default = "ap-southeast-2"
}

provider "http" {
  version = "~> 1.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "archive" {
  version = "~> 1.2"
}
