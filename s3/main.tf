/*
Cloud Infrastructure Automation Framework
Component: S3 Storage Module
*/

provider "aws" {
  region = "ap-south-1"
}

# Invoke your modular compliance bucket creation tier cleanly
module "infrastructure_compliance_storage" {
  source      = "./s3_compliance_bucket"
  environment = "dev"

  # Opt-in features (both default to false in the module)
  enable_versioning = true
  enable_lifecycle  = true

  # 🎯 DYNAMIC INPUT: Simply add or append bucket name strings to this variable array block
  bucket_names = [

  ]
}

# Output tracking loop maps straight to your terminal screen for verification
output "deployed_infrastructure_storage_arns" {
  value = module.infrastructure_compliance_storage.bucket_arns
}


