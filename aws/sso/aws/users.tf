# Locals for normalizing input data and processing user-group relationships
locals {
  # Step 0: Normalize user data by applying defaults
  normalized_users = [
    for user in var.users : {
      email        = user.email
      given_name   = user.given_name
      family_name  = user.family_name
      username     = coalesce(user.username, user.email)
      display_name = coalesce(user.display_name, "${user.given_name} ${user.family_name}")
      groups       = coalesce(user.groups, [])
    }
  ]

  # Step 1: Create a list of all user-group combinations
  # This flattens the normalized_users list to create individual user-group pairs
  # Example output:
  # [
  #   {
  #     email        = "john@example.com"
  #     username     = "john@example.com"
  #     display_name = "John Smith"
  #     group        = "developers"
  #   },
  #   {
  #     email        = "john@example.com"
  #     username     = "john@example.com"
  #     display_name = "John Smith"
  #     group        = "readonly"
  #   }
  # ]
  user_group_pairs = flatten([
    for user in local.normalized_users : [
      for group in user.groups : {
        email        = user.email
        username     = user.username
        display_name = user.display_name
        given_name   = user.given_name
        family_name  = user.family_name
        group        = group
      }
    ]
  ])

  # Step 2: Convert to a map with a unique key for each membership
  # Creates a map keyed by "username-group" for efficient lookup
  # Example output:
  # {
  #   "john@example.com-developers" = {
  #     email        = "john@example.com"
  #     username     = "john@example.com"
  #     display_name = "John Smith"
  #     group        = "developers"
  #   }
  # }
  user_group_memberships = {
    for pair in local.user_group_pairs :
    "${pair.username}-${pair.group}" => pair
  }
}