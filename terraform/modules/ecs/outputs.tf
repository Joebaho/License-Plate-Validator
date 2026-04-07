output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.app.zone_id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.app.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.app.name
}

output "alb_listener_arns" {
  description = "ARNs of ALB listeners"
  value = {
    http  = var.enable_alb_ssl ? null : aws_lb_listener.http[0].arn
    https = var.enable_alb_ssl ? aws_lb_listener.https[0].arn : null
  }
}

output "alb_target_group_arns" {
  description = "ARNs of ALB target groups"
  value = {
    app = aws_lb_target_group.app.arn
  }
}

output "autoscaling_target_arn" {
  description = "ARN of autoscaling target"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.ecs_target[0].resource_id : null
}

output "autoscaling_policy_arns" {
  description = "ARNs of autoscaling policies"
  value = {
    scale_up   = var.enable_autoscaling ? aws_appautoscaling_policy.scale_up[0].arn : null
    scale_down = var.enable_autoscaling ? aws_appautoscaling_policy.scale_down[0].arn : null
  }
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms"
  value = {
    cpu_high = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name : null
    cpu_low  = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.cpu_low[0].alarm_name : null
  }
}