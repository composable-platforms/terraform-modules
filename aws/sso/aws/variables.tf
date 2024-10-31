variable "users" {
  description = "List of users with their details and group assignments"
  type = list(object({
    email        = string
    given_name   = string
    family_name  = string
    username     = optional(string)           # defaults to email.
    display_name = optional(string)           # Optional display name field
    groups       = optional(list(string), []) # List of group names the user should belong to
  }))
}

variable "groups" {
  description = "Map of groups with optional descriptions"
  type = map(object({
    description = optional(string, "") # Optional description with empty string default
  }))

  default = {}
}
#  Example variable definition in terraform.tfvars
# groups = {
#   admins = {
#     description = "Full access to all resources"
#   }
#   readonly = {
#     description = "Read-only access to resources"
#   }
#   devs = {} # No description provided
# }

variable "permission_sets" {
  description = "Map of permission sets with their configuration"
  type = map(object({
    description      = optional(string, "")
    session_duration = optional(string, "PT8H")
    managed_policies = optional(list(string), []) # List of AWS managed policy ARNs
    inline_policy    = optional(string, "")       # Inline JSON policy
    relay_state      = optional(string, "")       # Optional URL to redirect users to after signing in
    tags             = optional(map(string), {})  # Optional resource tags
  }))
  default = {}
}

# Example
# permission_sets = {
#   "ReadOnlyAccess" = {
#     description = "Provides read-only access to all resources"
#     managed_policies = [
#       "arn:aws:iam::aws:policy/ReadOnlyAccess"
#     ]
#   }

#   "CustomDeveloperAccess" = {
#     description = "Custom permissions for developers"
#     managed_policies = [
#       "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
#     ]
#     custom_policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Action = ["s3:GetObject"]
#           Resource = ["arn:aws:s3:::my-dev-bucket/*"]
#         }
#       ]
#     })
#     relay_state = "https://console.aws.amazon.com/codecommit"
#     tags = {
#       Environment = "Development"
#     }
#   }
# }

# New variable for account assignments
variable "account_assignments" {
  description = "Map of AWS accounts and their permission set assignments to groups"
  type = map(object({
    account_name = optional(string, "")
    assignments = list(object({
      permission_set_name = string
      group_names         = list(string)
    }))
  }))
}

# Example
# "123456789012" = {
#     account_name = "Production"  # Optional friendly name
#     assignments = [
#       {
#         permission_set_name = "ReadOnlyAccess"
#         group_names        = ["developers", "analysts"]
#       },
#       {
#         permission_set_name = "AdminAccess"
#         group_names        = ["administrators"]
#       }
#     ]
#   },
#   "987654321098" = {
#     account_name = "Development"
#     assignments = [
#       {
#         permission_set_name = "PowerUserAccess"
#         group_names        = ["developers"]
#       },
#       {
#         permission_set_name = "ReadOnlyAccess"
#         group_names        = ["analysts", "auditors"]
#       }
#     ]
#   }