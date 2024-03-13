module "ecs_error_detection" {
  source = "../../"

  ecs_cluster_name = "example-cluster"
  environment      = "exammple"
  project          = "example"
  sns_topic_arn    = "arn:aws:sns:eu-central-1:123456789012:example"
}