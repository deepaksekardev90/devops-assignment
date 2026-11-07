/*
Wezva Technologies - Cloud Infrastructure Automation Framework
Component: S3 Storage Module
Author: Adam, Head of Platform
Optimized: For_each object looping, strict multi-tier backup archiving timelines.
*/

provider "aws" {
  region = "ap-south-1"
}

# Invoke your modular compliance bucket creation tier cleanly
module "infrastructure_compliance_storage" {
  source      = "./s3_compliance_bucket"
  environment = "production"

  # 🎯 DYNAMIC INPUT: Simply add or append bucket name strings to this variable array block
  bucket_names = [
    #"wezvatech-2026-tfstate",
    "wezvatech-dvc-data-lake",
    "wezvatech-rawdata-applog"
  ]
}

# Output tracking loop maps straight to your terminal screen for verification
output "deployed_infrastructure_storage_arns" {
  value = module.infrastructure_compliance_storage.bucket_arns
}


