output "tf_backend_bucket_name" {
  value = aws_s3_bucket.tf_state.id
}

output "tf_backend_dynamodb_name" {
  value = aws_dynamodb_table.tfstate_locks.id
}