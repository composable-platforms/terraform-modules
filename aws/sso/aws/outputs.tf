# Outputs
output "login_url" {
  description = "The url to access to login to AWS. For new users, click forgot password."
  value       = "https://${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}.awsapps.com/start"
}

## Need to go to url and trigger forgot password flow.check 
