variable "tags" {
  type        = map(string)
  description = "Default tags to apply on all created resources"
  default     = {}
}

variable "environment" {
  description = "Environment name"
}

variable "project" {
  description = "Project name"
}

variable "log_retention" {
  type        = number
  default     = 7
  description = "How long to keep logs"
}

variable "ecs_cluster_id" {
  type = string
  description = "ECS cluster id to be monitored"
}

variable "sns_topic_arn" {
  type = string
  description = "SNS topic where errors are sent"
}

variable "check_cron" {
  type = string
  description = "Cron expression when to run checks"
  default = "rate(1 hour)"
}