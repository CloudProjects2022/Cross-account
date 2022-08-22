terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21.0"
      configuration_aliases = [aws.crossbackup]
    }
  }
  required_version = ">=0.15.5"
}

provider "aws" {
  region = "us-east-2"
  profile = "dev"
}

provider "aws" {
  region = "us-east-2"
  alias = "crossbackup"
  profile = "prod"
}
