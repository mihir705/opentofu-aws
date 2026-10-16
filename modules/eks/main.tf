locals {
  create_cluster_role = var.cluster_role_arn == null
  create_node_role    = var.node_role_arn == null

  cluster_role_arn = coalesce(var.cluster_role_arn, try(aws_iam_role.cluster[0].arn, null))
  node_role_arn    = coalesce(var.node_role_arn, try(aws_iam_role.node[0].arn, null))

  cluster_log_group_name = "/aws/eks/${var.name}/cluster"

  addons = {
    for name, config in coalesce(var.addons, {
      "vpc-cni"    = {}
      "coredns"    = {}
      "kube-proxy" = {}
    }) : name => {
      addon_version               = try(config.addon_version, null)
      resolve_conflicts_on_create = try(config.resolve_conflicts_on_create, "OVERWRITE")
      resolve_conflicts_on_update = try(config.resolve_conflicts_on_update, "OVERWRITE")
      service_account_role_arn    = try(config.service_account_role_arn, null)
      configuration_values        = try(config.configuration_values, null)
    }
  }
}

check "subnet_count" {
  assert {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet_ids are required for EKS high availability."
  }
}

check "node_groups_required" {
  assert {
    condition     = length(var.node_groups) > 0
    error_message = "At least one node group is required."
  }
}

check "endpoint_access" {
  assert {
    condition     = var.endpoint_private_access || var.endpoint_public_access
    error_message = "At least one of endpoint_private_access or endpoint_public_access must be true."
  }
}

check "public_access_cidrs" {
  assert {
    condition     = !var.endpoint_public_access || length(var.public_access_cidrs) > 0
    error_message = "public_access_cidrs is required when endpoint_public_access is true."
  }
}

check "authentication_mode" {
  assert {
    condition     = contains(["API", "CONFIG_MAP", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be API, CONFIG_MAP, or API_AND_CONFIG_MAP."
  }
}

check "enabled_cluster_log_types" {
  assert {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "enabled_cluster_log_types must contain valid EKS control plane log types."
  }
}

check "node_group_scaling" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      group.min_size <= group.desired_size && group.desired_size <= group.max_size
    ])
    error_message = "Each node group requires min_size <= desired_size <= max_size."
  }
}

check "node_group_capacity_types" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      contains(["ON_DEMAND", "SPOT"], group.capacity_type)
    ])
    error_message = "Node group capacity_type must be ON_DEMAND or SPOT."
  }
}

check "node_group_instance_types" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      length(group.instance_types) > 0
    ])
    error_message = "Each node group requires at least one instance type."
  }
}

check "node_group_taint_effects" {
  assert {
    condition = alltrue([
      for group in var.node_groups : alltrue([
        for taint in coalesce(try(group.taints, null), []) :
        contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
      ])
    ])
    error_message = "Taint effect must be NO_SCHEDULE, NO_EXECUTE, or PREFER_NO_SCHEDULE."
  }
}

check "node_group_update_config" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      !(
        try(group.max_unavailable, null) != null &&
        try(group.max_unavailable_percentage, null) != null
      )
    ])
    error_message = "Specify only one of max_unavailable or max_unavailable_percentage per node group."
  }
}

check "addon_conflict_resolution" {
  assert {
    condition = alltrue([
      for addon in local.addons :
      contains(["NONE", "OVERWRITE", "PRESERVE"], addon.resolve_conflicts_on_create) &&
      contains(["NONE", "OVERWRITE", "PRESERVE"], addon.resolve_conflicts_on_update)
    ])
    error_message = "Add-on conflict resolution must be NONE, OVERWRITE, or PRESERVE."
  }
}

check "iam_role_name_length" {
  assert {
    condition     = length("${var.name}-cluster-role") <= 64 && length("${var.name}-node-role") <= 64
    error_message = "Cluster name is too long for auto-created IAM roles (max 64 characters including suffix)."
  }
}

check "node_group_subnet_count" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      try(group.subnet_ids, null) == null || length(group.subnet_ids) >= 1
    ])
    error_message = "Node group subnet_ids must contain at least one subnet when specified."
  }
}

check "node_group_disk_size" {
  assert {
    condition = alltrue([
      for group in var.node_groups :
      try(group.disk_size, 20) >= 20 && try(group.disk_size, 20) <= 16384
    ])
    error_message = "Node group disk_size must be between 20 and 16384 GiB."
  }
}

check "cloudwatch_log_retention" {
  assert {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.cloudwatch_log_retention_in_days
    )
    error_message = "cloudwatch_log_retention_in_days must be a valid CloudWatch Logs retention value."
  }
}

check "external_cluster_role_policies" {
  assert {
    condition     = local.create_cluster_role || var.cluster_role_arn != null
    error_message = "cluster_role_arn is required when auto-creating the cluster role is disabled."
  }
}

check "external_node_role_policies" {
  assert {
    condition     = local.create_node_role || var.node_role_arn != null
    error_message = "node_role_arn is required when auto-creating the node role is disabled."
  }
}

resource "aws_iam_role" "cluster" {
  count = local.create_cluster_role ? 1 : 0

  name = "${var.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  count = local.create_cluster_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_vpc_resource_controller" {
  count = local.create_cluster_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role" "node" {
  count = local.create_node_role ? 1 : 0

  name = "${var.name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_amazon_eks_worker_node_policy" {
  count = local.create_node_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_amazon_eks_cni_policy" {
  count = local.create_node_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_amazon_ec2_container_registry_read_only" {
  count = local.create_node_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

resource "aws_cloudwatch_log_group" "cluster" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = local.cluster_log_group_name
  retention_in_days = var.cloudwatch_log_retention_in_days

  tags = merge(var.tags, {
    Name = local.cluster_log_group_name
  })
}

resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_id != null ? [var.kms_key_id] : []

    content {
      provider {
        key_arn = encryption_config.value
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.cluster_amazon_eks_vpc_resource_controller,
    aws_cloudwatch_log_group.cluster,
  ]

  tags = merge(var.tags, {
    Name = var.name
  })
}

data "tls_certificate" "cluster" {
  count = var.create_oidc_provider ? 1 : 0

  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.create_oidc_provider ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.name}-oidc"
  })
}

resource "aws_eks_node_group" "node_group" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = each.key
  node_role_arn   = local.node_role_arn
  subnet_ids      = coalesce(try(each.value.subnet_ids, null), var.subnet_ids)
  capacity_type   = each.value.capacity_type
  ami_type        = try(each.value.ami_type, null)
  disk_size       = try(each.value.disk_size, null)
  instance_types  = each.value.instance_types
  labels          = try(each.value.labels, {})
  release_version = try(each.value.release_version, null)

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  dynamic "taint" {
    for_each = coalesce(try(each.value.taints, null), [])

    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  dynamic "update_config" {
    for_each = (
      try(each.value.max_unavailable, null) != null ||
      try(each.value.max_unavailable_percentage, null) != null
    ) ? [each.value] : []

    content {
      max_unavailable            = try(update_config.value.max_unavailable, null)
      max_unavailable_percentage = try(update_config.value.max_unavailable_percentage, null)
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.node_amazon_ec2_container_registry_read_only,
  ]

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_eks_addon" "addon" {
  for_each = local.addons

  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = each.key
  addon_version = try(each.value.addon_version, null)

  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values

  depends_on = [aws_eks_node_group.node_group]

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
