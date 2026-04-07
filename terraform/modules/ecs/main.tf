locals {
  # ALB and Target Group names have a strict 32-char max.
  resource_prefix = substr("${var.project_name}-${var.environment}", 0, 26)
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-cluster"
  })
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_ids.alb]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${local.resource_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-target-group"
  })
}

# HTTP Listener (only when SSL is disabled; replaced by redirect listener when SSL is on)
resource "aws_lb_listener" "http" {
  count = var.enable_alb_ssl ? 0 : 1

  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-http-listener"
  })
}

# HTTPS Listener (Optional)
resource "aws_lb_listener" "https" {
  count = var.enable_alb_ssl ? 1 : 0

  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-https-listener"
  })
}

# Redirect HTTP to HTTPS (Optional)
resource "aws_lb_listener" "http_redirect" {
  count = var.enable_alb_ssl ? 1 : 0

  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-http-redirect-listener"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container-${var.environment}"
      image = "${var.ecr_repository_url}:latest"

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      essential = true

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:${var.container_port}/api/health')\" || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-task-definition"
  })
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_ids.ecs]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container-${var.environment}"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.app
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-service"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# CloudWatch Metric Alarm for CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_autoscaling ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scaling_cpu_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up[0].arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-cpu-high-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_autoscaling ? 1 : 0

  alarm_name          = "${var.project_name}-cpu-low-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scaling_cpu_threshold / 2

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down[0].arn]

  tags = merge(var.tags, {
    Name = "${var.project_name}-cpu-low-alarm"
  })
}

# Application Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-scale-up-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-scale-down-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
