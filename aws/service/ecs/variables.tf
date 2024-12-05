variable "stage" {
  type        = string
  nullable    = false
  description = "One of dev, stage, prod, etc."
}

variable "project_name" {
  type        = string
  nullable    = false
  description = "The name of the project. Used for terraform cloud project and compose project name."
}

variable "service_name" {
  type        = string
  nullable    = false
  description = "The service key from the services section."
}

variable "image" {
  type        = string
  description = "The image `name:tag` for the main application container."
  validation {
    condition     = length(split(":", var.image)) == 2
    error_message = "Unexpected image tag format. Expecting image name and tag to split on colon."
  }
  nullable = false
}

variable "task_cpu" {
  default     = 256
  description = "This is the _entire_ task's CPU allocation. Should include margin for sidecars."
}

variable "task_memory" {
  default     = 512
  description = "This the _entire_ task's memory allocation. Should include margin for sidecars."
}

variable "container_entrypoint" {
  type    = list(string)
  default = null
}

variable "container_command" {
  type    = list(string)
  default = null
}


variable "container_environment" {
  type        = map(string)
  default     = {}
  description = "Environment variables to pass to container as a map of key-value pairs"
}

variable "container_secrets" {
  type        = map(string)
  default     = {}
  description = "Secrets from Secrets Manager or Parameter Store to inject into container environment. Map of environment variable names to ARNs"
}


variable "ports" {
  type        = list(string)
  default     = []
  description = "List of port mappings in Docker Compose format (e.g. ['8080:80', '443:443']) TCP Protocol is assumed."
}


variable "ephemeral_storage" {
  type        = number
  description = "The size of the ephemeral storage for the task (unspecified/null defaults to 20GiB). Min: 21GiB; Max: 200GiB"
  nullable    = true
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks to run"
  default     = 1
}

variable "custom_task_iam_policy" {
  description = "Custom policy to add to the task role. Defined in your main.tf with `data.aws_policy_document.mypolicy` and passed into this variable with `data.aws_policy_document.mypolicy.json`"
  type        = any
  default     = null
}

variable "custom_task_exec_iam_policy" {
  description = "Custom policy to add to the task exec role. Defined in your main.tf with `data.aws_policy_document.mypolicy` and passed into this variable with `data.aws_policy_document.mypolicy.json`"
  type        = any
  default     = null
}

variable "custom_sidecars" {
  description = "Sidecars to add to main app container"
  type        = list(any)
  default     = []
}

variable "log_retention" {
  description = "Days to retain Cloudwatch logs. 0 for indefinitely"
  default     = 90
}
