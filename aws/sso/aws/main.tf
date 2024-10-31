# provider.tf
# variables.tf
data "aws_caller_identity" "current" {}
# Get the SSO instance
data "aws_ssoadmin_instances" "main" {}

# Locals for processing user-group relationships
locals {
  # Step 1: Create a list of all user-group combinations
  # Example output for user_group_pairs:
  # [
  #   {
  #     email = "lukediliberto@gmail.com"
  #     group = "readonly"
  #   },
  #   {
  #     email = "lukediliberto@gmail.com"
  #     group = "administrators"
  #   },
  #   {
  #     email = "jane.doe@example.com"
  #     group = "developers"
  #   }
  # ]
  user_group_pairs = flatten([
    for user in var.users : [
      for group in user.groups : {
        email = user.email
        group = group
      }
    ] if length(user.groups) > 0
  ])

  # Step 2: Convert to a map with a unique key for each membership
  # Example output for user_group_memberships:
  # {
  #   "lukediliberto@gmail.com-readonly" = {
  #     email = "lukediliberto@gmail.com"
  #     group = "readonly"
  #   }
  #   "lukediliberto@gmail.com-administrators" = {
  #     email = "lukediliberto@gmail.com"
  #     group = "administrators"
  #   }
  #   "jane.doe@example.com-developers" = {
  #     email = "jane.doe@example.com"
  #     group = "developers"
  #   }
  # }
  user_group_memberships = {
    for pair in local.user_group_pairs :
    "${pair.email}-${pair.group}" => pair
  }
  # Permission set managed policy processing
  # Example output:
  # {
  #   "ReadOnlyAccess-ReadOnlyAccess" = {
  #     pset_name  = "ReadOnlyAccess"
  #     policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  #   }
  # }
  managed_policy_attachments = merge([
    for pset_name, pset in var.permission_sets : {
      for policy_arn in pset.managed_policies :
      "${pset_name}-${basename(policy_arn)}" => {
        pset_name  = pset_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # Permission set inline policy processing
  # Example output:
  # {
  #   "CustomDeveloperAccess" = jsonencode({ ... })
  # }
  inline_policy_attachments = {
    for pset_name, pset in var.permission_sets :
    pset_name => pset.inline_policy
    if pset.inline_policy != ""
  }
}

# Create Groups
resource "aws_identitystore_group" "groups" {
  for_each = var.groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = each.key
  description       = each.value.description
}

# Create Users
resource "aws_identitystore_user" "users" {
  for_each          = { for user in var.users : user.username => user }
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = coalesce(each.value.display_name, "${each.value.given_name} ${each.value.family_name}")
  user_name         = coalesce(each.value.username, each.value.email)

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

# # Add Users to Groups
resource "aws_identitystore_group_membership" "user_group_memberships" {
  for_each = local.user_group_memberships

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  group_id          = aws_identitystore_group.groups[each.value.group].group_id
  member_id         = aws_identitystore_user.users[each.value.email].user_id
}

locals {
  # New locals for account assignments
  # Step 1: Flatten account assignments into individual mappings
  # Example output:
  # [
  #   {
  #     account_id = "123456789012"
  #     permission_set_name = "ReadOnlyAccess"
  #     group_name = "developers"
  #   },
  #   {
  #     account_id = "123456789012"
  #     permission_set_name = "ReadOnlyAccess"
  #     group_name = "analysts"
  #   }
  # ]
  account_assignments_flat = flatten([
    for account_id, account in var.account_assignments : [
      for assignment in account.assignments : [
        for group_name in assignment.group_names : {
          account_id          = account_id
          permission_set_name = assignment.permission_set_name
          group_name          = group_name
        }
      ]
    ]
  ])

  # Step 2: Create a map with unique keys for each assignment
  # Example output:
  # {
  #   "123456789012-ReadOnlyAccess-developers" = {
  #     account_id = "123456789012"
  #     permission_set_name = "ReadOnlyAccess"
  #     group_name = "developers"
  #   }
  # }
  account_assignments_map = {
    for assignment in local.account_assignments_flat :
    "${assignment.account_id}-${assignment.permission_set_name}-${assignment.group_name}" => assignment
  }
}

# New resource for account assignments
resource "aws_ssoadmin_account_assignment" "account_assignments" {
  for_each = local.account_assignments_map

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permission_sets[each.value.permission_set_name].arn

  principal_id   = aws_identitystore_group.groups[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

# Outputs
output "sso_instance_arn" {
  description = "ARN of the SSO instance"
  value       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

output "identity_store_id" {
  description = "ID of the Identity Store"
  value       = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

output "admin_group_id" {
  description = "ID of the Administrators group"
  value       = aws_identitystore_group.administrators.group_id
}

output "admin_permission_set_arn" {
  description = "ARN of the Administrator permission set"
  value       = aws_ssoadmin_permission_set.administrator.arn
}

output "login_url" {
  description = "The url to access to login to AWS. For new users, click forgot password."
  value       = "https://${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}.awsapps.com/start"
}

## Need to go to url and trigger forgot password flow.check 
# lpHRwY5mMbom!




# Define Permission Sets
resource "aws_ssoadmin_permission_set" "permission_sets" {
  for_each = var.permission_sets

  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name             = each.key
  description      = each.value.description
  session_duration = each.value.session_duration
  relay_state      = each.value.relay_state

  tags = each.value.tags
}
