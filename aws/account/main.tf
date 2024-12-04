# locals {
#   # Use subscriber_emails if provided, otherwise fall back to account_email
#   notification_emails = length(var.budget_config.subscriber_emails) > 0 ? var.budget_config.subscriber_emails : [var.account_email]
# }

resource "aws_organizations_account" "account" {
  name              = var.account_name
  email             = var.account_email
  parent_id         = var.account_parent_id
  role_name         = var.role_name
  close_on_deletion = var.close_on_deletion

}

resource "aws_ssoadmin_account_assignment" "account_assignments" {
  # stringify sso_assignments to make iterable set
  for_each = var.sso_assignments

  instance_arn       = var.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn
  principal_id       = each.value.group_id
  principal_type     = "GROUP"

  target_id   = aws_organizations_account.account.id
  target_type = "AWS_ACCOUNT"
}

# resource "aws_budgets_budget" "monthly_budget" {
#   account_id   = aws_organizations_account.account.id
#   name         = "${var.account_name}-account-monthly-budget-${aws_organizations_account.account.id}"
#   budget_type  = "COST"
#   limit_amount = var.budget_config.limit_amount
#   limit_unit   = "USD"
#   time_unit    = "MONTHLY"

#   dynamic "notification" {
#     for_each = var.budget_config.actual_thresholds_for_notification
#     content {
#       comparison_operator        = "GREATER_THAN"
#       threshold                  = notification.value
#       threshold_type             = "PERCENTAGE"
#       notification_type          = "ACTUAL"
#       subscriber_email_addresses = local.notification_emails
#     }
#   }

#   dynamic "notification" {
#     for_each = var.budget_config.forecast_thresholds_for_notification
#     content {
#       comparison_operator        = "GREATER_THAN"
#       threshold                  = notification.value
#       threshold_type             = "PERCENTAGE"
#       notification_type          = "ACTUAL"
#       subscriber_email_addresses = local.notification_emails
#     }
#   }
# }
