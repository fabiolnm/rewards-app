#!/bin/bash
set -e

# This script helps debug the current ECS deployment by fetching CloudWatch logs

SERVICE_NAME="${1:-rewards-app-web}"
CLUSTER_NAME="rewards-app-cluster"

echo "Fetching logs for service: $SERVICE_NAME"
echo ""

# Get the most recent task ARN
echo "Getting recent tasks..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns[0]' \
  --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
  echo "No tasks found for service $SERVICE_NAME"
  exit 1
fi

echo "Task ARN: $TASK_ARN"
TASK_ID=$(echo $TASK_ARN | awk -F/ '{print $NF}')
echo "Task ID: $TASK_ID"
echo ""

# Get task details
echo "Getting task details..."
aws ecs describe-tasks \
  --cluster "$CLUSTER_NAME" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].{lastStatus:lastStatus,desiredStatus:desiredStatus,stoppedReason:stoppedReason,containers:containers[*].{name:name,exitCode:exitCode,reason:reason}}' \
  --output json

echo ""

# Get log configuration from task definition
echo "Getting log configuration..."
TASK_DEF=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].taskDefinition' \
  --output text)

LOG_CONFIG=$(aws ecs describe-task-definition \
  --task-definition "$TASK_DEF" \
  --query 'taskDefinition.containerDefinitions[0].logConfiguration.options')

LOG_GROUP=$(echo $LOG_CONFIG | jq -r '.["awslogs-group"]')
LOG_PREFIX=$(echo $LOG_CONFIG | jq -r '.["awslogs-stream-prefix"]')

# Determine container name from service name
if [[ "$SERVICE_NAME" == *"web"* ]]; then
  CONTAINER_NAME="web"
elif [[ "$SERVICE_NAME" == *"api"* ]]; then
  CONTAINER_NAME="api"
else
  CONTAINER_NAME="app"
fi

LOG_STREAM="${LOG_PREFIX}/${CONTAINER_NAME}/${TASK_ID}"

echo "Log Group: $LOG_GROUP"
echo "Log Stream: $LOG_STREAM"
echo ""
echo "==================== LOGS ===================="
echo ""

aws logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --limit 200 \
  --query 'events[*].message' \
  --output text || {
    echo ""
    echo "Could not fetch logs from CloudWatch."
    echo "The log stream might not exist yet or the task might not have started."
    echo ""
    echo "Check CloudWatch manually at:"
    echo "https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/$LOG_GROUP/log-events/$LOG_STREAM"
    exit 1
  }
