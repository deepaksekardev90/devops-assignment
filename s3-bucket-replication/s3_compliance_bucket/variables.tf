variable "bucket_names" {
  type        = list(string)
  description = "A list of unique S3 bucket name strings to create and apply compliance policies against"
}

variable "environment" {
  type        = string
  description = "Deployment environment namespace prefix (e.g. production, staging)"
  default     = "production"
}

variable "enable_replication" {
  type        = bool
  description = "Create replica buckets in the destination region and replicate every source bucket to them"
  default     = true
}

variable "destination_bucket_suffix" {
  type        = string
  description = "Suffix appended to each source bucket name to build the replica bucket name"
  default     = "-replica"
}

variable "replica_storage_class" {
  type        = string
  description = "Storage class used for replicated objects in the destination bucket"
  default     = "STANDARD"
}
