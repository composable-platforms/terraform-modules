output "account_id" {
    value = aws_organizations_account.account.id
}

output "organization_access_role_name" {
    value = aws_organizations_account.account.role_name
}