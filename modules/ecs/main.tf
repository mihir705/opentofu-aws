data "aws_region" "current" {}

data "aws_iam_policy_document" "execution_assume_role" {
  count = var.execution_role_arn == null ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

locals {
  create_execution_role = var.execution_role_arn == null
  execution_role_arn    = coalesce(var.execution_role_arn, try(aws_iam_role.execution[0].arn, null))

  service_subnet_ids = {
    for svc_name, svc in var.services : svc_name => coalesce(try(svc.subnet_ids, null), var.subnet_ids)
  }

  service_security_group_ids = {
    for svc_name, svc in var.services : svc_name => coalesce(try(svc.security_group_ids, null), var.security_group_ids)
  }

  container_definitions = {
    for svc_name, svc in var.services : svc_name => [
      for cname, container in svc.containers : merge(
        {
          name      = cname
          image     = container.image
          essential = try(container.essential, true)
        },
        try(container.cpu, null) != null ? { cpu = container.cpu } : {},
        try(container.memory, null) != null ? { memory = container.memory } : {},
        length(coalesce(try(container.command, null), [])) > 0 ? { command = container.command } : {},
        length(coalesce(try(container.entry_point, null), [])) > 0 ? { entryPoint = container.entry_point } : {},
        length(keys(coalesce(try(container.environment, null), {}))) > 0 ? {
          environment = [
            for key, value in container.environment : {
              name  = key
              value = value
            }
          ]
        } : {},
        length(coalesce(try(container.secrets, null), [])) > 0 ? {
          secrets = [
            for secret in container.secrets : {
              name      = secret.name
              valueFrom = secret.value_from
            }
          ]
        } : {},
        length(coalesce(try(container.port_mappings, null), [])) > 0 ? {
          portMappings = [
            for mapping in container.port_mappings : merge(
              {
                containerPort = mapping.container_port
                protocol      = mapping.protocol
              },
              try(mapping.host_port, null) != null ? { hostPort = mapping.host_port } : {}
            )
          ]
        } : {},
        {
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.service[svc_name].name
              awslogs-region        = data.aws_region.current.region
              awslogs-stream-prefix = cname
            }
          }
        }
      )
    ]
  }
}

check "execution_role_name_length" {
  assert {
    condition     = var.execution_role_arn != null || length("${var.name}-execution-role") <= 64
    error_message = "Cluster name is too long for auto-created execution role (max 64 characters including suffix)."
  }
}

check "services_required" {
  assert {
    condition     = length(var.services) > 0
    error_message = "At least one service is required."
  }
}

check "subnet_ids_required" {
  assert {
    condition = alltrue([
      for svc_name, svc in var.services :
      length(local.service_subnet_ids[svc_name]) > 0
    ])
    error_message = "Each service requires subnet_ids on the service or cluster."
  }
}

check "security_group_ids_required" {
  assert {
    condition = alltrue([
      for svc_name, svc in var.services :
      length(local.service_security_group_ids[svc_name]) > 0
    ])
    error_message = "Each service requires security_group_ids on the service or cluster."
  }
}

check "launch_type_values" {
  assert {
    condition = alltrue([
      for svc in var.services :
      contains(["FARGATE", "EC2"], svc.launch_type)
    ])
    error_message = "service launch_type must be FARGATE or EC2."
  }
}

check "desired_count_values" {
  assert {
    condition = alltrue([
      for svc in var.services :
      svc.desired_count >= 0
    ])
    error_message = "Each service desired_count must be 0 or greater."
  }
}

check "container_images_required" {
  assert {
    condition = alltrue([
      for svc in var.services : alltrue([
        for container in svc.containers :
        try(container.image, null) != null && container.image != ""
      ])
    ])
    error_message = "Each container requires a non-empty image."
  }
}

check "containers_required" {
  assert {
    condition = alltrue([
      for svc in var.services :
      length(svc.containers) > 0
    ])
    error_message = "Each service requires at least one container."
  }
}

check "fargate_cpu_memory_minimum" {
  assert {
    condition = alltrue([
      for svc in var.services :
      svc.launch_type != "FARGATE" || (svc.cpu >= 256 && svc.memory >= 512)
    ])
    error_message = "FARGATE services require cpu >= 256 and memory >= 512."
  }
}

check "load_balancer_attachments" {
  assert {
    condition = alltrue([
      for svc in var.services : alltrue([
        for lb in coalesce(try(svc.load_balancers, null), []) :
        contains(keys(svc.containers), lb.container_name)
      ])
    ])
    error_message = "Each load balancer container_name must match a container key in the service."
  }
}

resource "aws_iam_role" "execution" {
  count = local.create_execution_role ? 1 : 0

  name = "${var.name}-execution-role"

  assume_role_policy = data.aws_iam_policy_document.execution_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${var.name}-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  count = local.create_execution_role ? 1 : 0

  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "cluster" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  count = length(var.capacity_providers) > 0 ? 1 : 0

  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    capacity_provider = var.default_capacity_provider
    weight            = 1
    base              = 0
  }
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/ecs/${var.name}/${each.key}"
  retention_in_days = each.value.log_retention_in_days

  tags = merge(var.tags, {
    Name = "/ecs/${var.name}/${each.key}"
  })
}

resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${var.name}-${each.key}"
  requires_compatibilities = [each.value.launch_type]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = coalesce(try(each.value.execution_role_arn, null), local.execution_role_arn)
  task_role_arn            = try(each.value.task_role_arn, null)

  container_definitions = jsonencode(local.container_definitions[each.key])

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type
  platform_version = each.value.launch_type == "FARGATE" ? each.value.platform_version : null

  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  health_check_grace_period_seconds  = try(each.value.health_check_grace_period_seconds, null)
  enable_execute_command             = each.value.enable_execute_command

  network_configuration {
    subnets          = local.service_subnet_ids[each.key]
    security_groups  = local.service_security_group_ids[each.key]
    assign_public_ip = each.value.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = coalesce(try(each.value.load_balancers, null), [])

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  tags = merge(var.tags, {
    Name = each.key
  })

  depends_on = [aws_iam_role_policy_attachment.execution]
}
