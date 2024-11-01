variable "account_name" {
  description = "Account name, this is the name will be used to determine which roles to use. dev, stage, prod, shared, security, something predictable. "
  type        = string
}

variable "account_email" {
  description = "Root account email. Should be a distribution list if a company. "
  type        = string
}

variable "account_parent_id" {
  type     = string
  nullable = true
}

variable "close_on_deletion" {
  type    = bool
  default = false
}

variable "role_name" {
  description = "This role is used to create resources in the account by the management account that are necessary before the account can start managing itself."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "sso_assignments" {
  description = "Map of SSO assignments with direct ARN/ID references"
  type = map(object({
    permission_set_arn = string # Direct ARN reference
    group_id           = string # Direct group ID reference
  }))
  default = {}
}
# the keys give us a way to easily lookup what we created from another module.
# for eaxmple, how we are getting the ARNs form the friendly name out of sso module
# sso_assignments = {
#   "readonly-developers" = {
#     permission_set_arn = module.sso.permission_sets["ReadOnlyAccess"].arn,
#     group_id          = module.sso.groups["developers"].id
#   },
#   "admin-platform" = {
#     permission_set_arn = module.sso.permission_sets["AdminAccess"].arn,
#     group_id          = module.sso.groups["platform"].id
#   }
# }


variable "sso_instance_arn" {
  description = "ARN of the SSO instance to use."
  type        = string
}