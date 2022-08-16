terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21.0"
      configuration_aliases = [aws.crossbackup, aws.replication]
    }
  }
  required_version = ">=0.15.5"
}

provider "aws" {
    region = "us-east-1"
    profile = "myown"
}

# provider "aws" {
#     region = "ca-central-1"
#     alias = "crossbackup"
#     profile = "prod"
# }

# provider "aws" {
#     region = "us-west-1"
#     alias = "replication"
#     profile = "dev"
# }