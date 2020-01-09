terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = local.region
  version = "~> 2.26"
}

provider "archive" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}
