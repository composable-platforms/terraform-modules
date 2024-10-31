# provider.tf
# variables.tf
# Get the SSO instance
data "aws_ssoadmin_instances" "main" {}

# Locals for processing user-group relationships
locals {
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
  for_each          = { for user in local.normalized_users : user.username => user }
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = each.value.display_name
  user_name         = each.value.username

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
