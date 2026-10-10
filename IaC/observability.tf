resource "aws_sns_topic" "dlq_alerts" {
  name = "${local.name_prefix}-dlq-alerts"
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name        = "${local.name_prefix}-dlq-messages-alarm"
  alarm_description = "Alerta cuando existen mensajes sin procesar en la DLQ."

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"

  statistic          = "Average"
  period             = 60
  evaluation_periods = 1

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [
    aws_sns_topic.dlq_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}