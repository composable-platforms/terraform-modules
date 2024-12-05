variable "project_name" {
  description = "Project name to provider ECR namespace"
  type        = string
}

variable "service_name" {
  description = "Name of the service for the repo"
  type        = string
}

variable "trusted_account_ids" {
  type        = list(string)
  description = "Account IDs of trusted accounts that can created, push and pull to ECR"
  default     = []
}
