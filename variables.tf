variable "tags" {
  type        = map(string)
  description = "Default tags to apply on all created resources"
  default     = {}
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "log_retention" {
  type        = number
  default     = 7
  description = "How long to keep logs"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name to be monitored"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic where errors are sent"
}

variable "check_cron" {
  type        = string
  description = "Cron expression when to run checks"
  default     = "rate(1 hour)"
}