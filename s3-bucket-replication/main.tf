provider "aws" {
  region = "ap-south-1"
}

# Destination region for replicas
provider "aws" {
  alias  = "destination"
  region = "ap-southeast-1"
}

# Invoke your modular compliance bucket creation tier cleanly
module "infrastructure_compliance_storage" {
  source      = "./s3_compliance_bucket"
  environment = "production"

  # Pass both providers into the module
  providers = {
    aws             = aws
    aws.destination = aws.destination
  }

  # DYNAMIC INPUT: Simply add or append bucket name strings to this variable array block
  bucket_names = [
    "fintech-dvc-data-lake",
    "fintech-rawdata-applog"
  ]

  # Cross-region replication (replica names become <bucket>-replica)
  enable_replication        = true
  destination_bucket_suffix = "-replica"
}

# Output tracking loop maps straight to your terminal screen for verification
output "deployed_infrastructure_storage_arns" {
  value = module.infrastructure_compliance_storage.bucket_arns
}

output "replica_storage_arns" {
  value = module.infrastructure_compliance_storage.replica_bucket_arns
}

output "replication_role_arn" {
  value = module.infrastructure_compliance_storage.replication_role_arn
}
