variable "allowed_repos" {
  description = "The repos, namespaced by the org my-org/repo1, my-org/repo2 that can additioanlly use the role"
  type        = list(string)
  default     = []
  validation {
    condition = length(var.allowed_repos) == 0 || alltrue([
      for repo in var.allowed_repos :
      can(regex("^[a-zA-Z0-9-]+/[a-zA-Z0-9-_\\.]+$", repo))
    ])
    error_message = "Each repository must be properly namespaced with an organization in the format 'org/repo'. Valid characters for org are a-z, A-Z, 0-9, and hyphens. Valid characters for repo are a-z, A-Z, 0-9, hyphens, underscores, and dots."
  }
}
