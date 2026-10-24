variable "subscription_id" {
  description = "Target subscription for this environment."
  type        = string
}

variable "cloud_environment" {
  description = "public (Azure Commercial) or usgovernment (Azure Government)."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "usgovernment"], var.cloud_environment)
    error_message = "cloud_environment must be public or usgovernment."
  }
}

variable "environment" {
  description = "dev | qa | staging | prod"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be dev, qa, staging or prod."
  }
}

variable "workload" {
  type    = string
  default = "demo"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "image_tag" {
  description = "Immutable image tag (git SHA). Never 'latest'."
  type        = string
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
