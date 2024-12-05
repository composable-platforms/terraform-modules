variable "aws_region" {
  default = "us-west-2"
}

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
  default     = 1024
  description = "This is the _entire_ task's CPU allocation. Should include margin for sidecars."
  nullable    = false
}

variable "task_memory" {
  default     = 2048
  description = "This the _entire_ task's memory allocation. Should include margin for sidecars."
  nullable    = false
}

variable "entrypoint" {
  type    = list(string)
  default = null
}

variable "command" {
  type    = list(string)
  default = null
}

variable "environment" {
  type        = map(any)
  default     = {}
  nullable    = false # if we get a null value, we set it to empty map so iteration doesn't break
  description = "Environment for main application container. Values containing valid secret or parameter ARNs will use the valueFrom syntax for secrets injection in ECS."
}

variable "container_port" {
  type        = number
  description = "If no container port is specified, set to 9999 so envoy can still spin up."
}

variable "ephemeral_storage" {
  type        = number
  description = "The size of the ephemeral storage for the task (unspecified/null defaults to 20GiB). Min: 21GiB; Max: 200GiB"
  nullable    = true
}


# alb.tf
# definitions.tf

# autoscaling.tf
variable "replicas" {
  type        = number
  description = "If null, default in locals to 1 (non-prod) and 2 (prod) and include autoscaling."
  nullable    = true
}

variable "max_replicas" {
  type        = number
  description = "If null, default in locals to 2 (non-prod) and 6 (prod) and include autoscaling."
  nullable    = true
}


variable "cloudwatch_alarms" {
  type        = map(any)
  default     = {}
  description = "Default locals object TBD when needed by services for customization."
  nullable    = true
}

# TBD
# variable "depends_on_containers" {
#   type        = list(object({ containerName = string, condition = string }))
#   default     = null
#   description = "condition can be START, COMPLETE, SUCCESS, HEALTHY"
# }

variable "custom_task_iam_policy" {
  description = "Custom policy to add to the task role. Defined in your main.tf with `data.aws_policy_document.mypolicy` and passed into this variable with `data.aws_policy_document.mypolicy.json`"
  type        = any
  default     = null
  nullable    = true
}

variable "custom_task_exec_iam_policy" {
  description = "Custom policy to add to the task exec role. Defined in your main.tf with `data.aws_policy_document.mypolicy` and passed into this variable with `data.aws_policy_document.mypolicy.json`"
  type        = any
  default     = null
  nullable    = true
}
