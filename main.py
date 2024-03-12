import itertools
import os

import boto3

ecs = boto3.client('ecs')
sns = boto3.client('sns')

cluster = os.getenv('ECS_CLUSTER')
sns_arn = os.getenv('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    services = ecs.list_services(
        cluster=cluster,
        maxResults=100
    )['serviceArns']

    services_chunks = [services[x:x + 10] for x in range(0, len(services), 10)]

    described_srv = []
    for srvs in services_chunks:
        desc_chunk = ecs.describe_services(
            cluster=cluster,
            services=srvs,
        )['services']
        described_srv.extend(desc_chunk)

    deployments = list(map(lambda x: x['deployments'], described_srv))
    deployments = list(itertools.chain(*deployments))
    in_progress = list(filter(lambda x: x['rolloutState'] == 'IN_PROGRESS', deployments))
    failing_deployments = list(filter(lambda x: x['failedTasks'] >= 5, in_progress))
    if failing_deployments == 0:
        exit(0)
    failing_task_definitions = list(map(lambda x: x['taskDefinition'], failing_deployments))
    message = f"ECS task definitions are failing: {','.join(failing_task_definitions)}"
    sns.publish(
        TopicArn=sns_arn,
        Message=message,
        Subject='ECS Deployment Error',
    )
