# Outputs
output "login_url" {
  description = "The url to access to login to AWS. For new users, click forgot password."
  value       = "https://${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}.awsapps.com/start"
}

output "sso_instance_arn" {
  value = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

## Need to go to url and trigger forgot password flow.check 

output "groups" {
  value = aws_identitystore_group.groups
}

output "permission_sets" {
  value = aws_ssoadmin_permission_set.permission_sets
}
