variable "bucket_names" {
  type        = list(string)
  description = "A list of unique S3 bucket name strings to create and apply compliance policies against"
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 versioning on the buckets (opt-in)"
  default     = false
}

variable "enable_lifecycle" {
  type        = bool
  description = "Attach the tiered lifecycle policy to the buckets (opt-in)"
  default     = false
}

variable "environment" {
  type        = string
  description = "Deployment environment namespace prefix (e.g. production, staging)"
  default     = "production"
}

