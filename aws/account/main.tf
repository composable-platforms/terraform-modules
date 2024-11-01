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
