variable "s3_bucket_name" {
  description = "Name of the S3 bucket for tf state: default tfstate-{account_id}"
  type        = string
  default     = null # Will be constructed from other variables if not provided

  validation {
    condition     = var.s3_bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be lowercase, can contain dots and hyphens, must start and end with letter/number."
  }
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "tfstate-locks" # Will be constructed from other variables if not provided
}
