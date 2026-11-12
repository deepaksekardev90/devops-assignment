terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"

      # The module expects the caller to pass a second provider for the replica region
      configuration_aliases = [aws.destination]
    }
  }
}
