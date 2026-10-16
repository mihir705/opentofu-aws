module "s3" {
  source = "../../modules/s3"

  for_each = var.buckets

  bucket_name             = each.value.bucket_name
  force_destroy           = each.value.force_destroy
  versioning_enabled      = each.value.versioning_enabled
  sse_algorithm           = each.value.sse_algorithm
  kms_key_arn             = each.value.kms_key_arn
  bucket_key_enabled      = each.value.bucket_key_enabled
  object_ownership        = each.value.object_ownership
  block_public_acls       = each.value.block_public_acls
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = each.value.ignore_public_acls
  restrict_public_buckets = each.value.restrict_public_buckets
  access_logging          = each.value.access_logging
  lifecycle_rules         = each.value.lifecycle_rules
  bucket_policy_json      = each.value.bucket_policy_json
  cors_rules              = each.value.cors_rules
  tags                    = merge(var.default_tags, each.value.tags)
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  for_each = var.secrets

  name                    = try(each.value.name, null)
  name_prefix             = try(each.value.name_prefix, null)
  description             = each.value.description
  kms_key_id              = each.value.kms_key_id
  recovery_window_in_days = each.value.recovery_window_in_days
  secret_string           = each.value.secret_string
  secret_binary           = each.value.secret_binary
  generate_random_password = each.value.generate_random_password
  ignore_secret_changes   = each.value.ignore_secret_changes
  rotation                = each.value.rotation
  resource_policy_json    = each.value.resource_policy_json
  replica_regions         = each.value.replica_regions
  tags                    = merge(var.default_tags, each.value.tags)
}

module "kms" {
  source = "../../modules/kms"

  for_each = var.kms_keys

  providers = {
    aws.replica = aws.replica
  }

  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = each.value.enable_key_rotation
  multi_region            = each.value.multi_region
  replica_region          = each.value.replica_region
  key_policy_json         = each.value.key_policy_json
  allowed_services        = each.value.allowed_services
  policy_statements       = each.value.policy_statements
  aliases                 = each.value.aliases
  tags                    = merge(var.default_tags, each.value.tags)
}

module "lambda" {
  source = "../../modules/lambda"

  for_each = var.lambda_functions

  depends_on = [aws_s3_object.lambda_package]

  function_name                  = each.value.function_name
  role_name                      = each.value.role_name
  description                    = each.value.description
  package_type                   = each.value.package_type
  runtime                        = each.value.runtime
  handler                        = each.value.handler
  filename                       = each.value.filename
  s3_bucket                      = each.value.s3_bucket
  s3_key                         = each.value.s3_key
  s3_object_version              = try(local.lambda_package_versions[each.key], each.value.s3_object_version)
  source_code_hash               = each.value.source_code_hash
  image_uri                      = each.value.image_uri
  memory_size                    = each.value.memory_size
  timeout                        = each.value.timeout
  architectures                  = each.value.architectures
  environment_variables          = each.value.environment_variables
  kms_key_arn                    = each.value.kms_key_arn
  layers                         = each.value.layers
  ephemeral_storage_size         = each.value.ephemeral_storage_size
  reserved_concurrent_executions = each.value.reserved_concurrent_executions
  tracing_mode                   = each.value.tracing_mode
  vpc_config                     = each.value.vpc_config
  dead_letter_config             = each.value.dead_letter_config
  create_log_group               = each.value.create_log_group
  log_retention_in_days          = each.value.log_retention_in_days
  policy_statements              = each.value.policy_statements
  function_url                   = each.value.function_url
  event_source_mappings          = each.value.event_source_mappings
  tags                           = merge(var.default_tags, each.value.tags)
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  for_each = var.cloudfront_distributions

  distribution_comment             = each.value.distribution_comment
  enabled                          = each.value.enabled
  price_class                      = each.value.price_class
  origin_id                        = each.value.origin_id
  default_root_object              = each.value.default_root_object
  spa_fallback                     = each.value.spa_fallback
  wait_for_deployment              = each.value.wait_for_deployment
  cache_policy_id                  = each.value.cache_policy_id
  origin_request_policy_id         = each.value.origin_request_policy_id
  response_headers_policy_id       = each.value.response_headers_policy_id
  create_origin_bucket             = each.value.create_origin_bucket
  origin_bucket_name               = each.value.origin_bucket_name
  origin_bucket_force_destroy      = each.value.origin_bucket_force_destroy
  origin_bucket_versioning_enabled = each.value.origin_bucket_versioning_enabled
  origin_sse_algorithm             = each.value.origin_sse_algorithm
  origin_kms_key_arn               = each.value.origin_kms_key_arn
  origin_bucket_key_enabled        = each.value.origin_bucket_key_enabled
  existing_origin_bucket_id                   = each.value.existing_origin_bucket_id
  existing_origin_bucket_arn                  = each.value.existing_origin_bucket_arn
  existing_origin_bucket_regional_domain_name = each.value.existing_origin_bucket_regional_domain_name
  manage_origin_bucket_policy                 = each.value.manage_origin_bucket_policy
  origin_path                      = each.value.origin_path
  viewer_protocol_policy           = each.value.viewer_protocol_policy
  allowed_methods                  = each.value.allowed_methods
  cached_methods                   = each.value.cached_methods
  compress                         = each.value.compress
  min_ttl                          = each.value.min_ttl
  default_ttl                      = each.value.default_ttl
  max_ttl                          = each.value.max_ttl
  forward_query_string             = each.value.forward_query_string
  forward_cookies                  = each.value.forward_cookies
  forwarded_cookie_names           = each.value.forwarded_cookie_names
  forward_headers                  = each.value.forward_headers
  ordered_cache_behaviors          = each.value.ordered_cache_behaviors
  function_associations            = each.value.function_associations
  origin_bucket_policy_statements  = each.value.origin_bucket_policy_statements
  custom_error_responses           = each.value.custom_error_responses
  aliases                          = each.value.aliases
  acm_certificate_arn              = each.value.acm_certificate_arn
  minimum_protocol_version         = each.value.minimum_protocol_version
  ssl_support_method               = each.value.ssl_support_method
  geo_restriction_type             = each.value.geo_restriction_type
  geo_restriction_locations        = each.value.geo_restriction_locations
  logging_config                   = each.value.logging_config
  web_acl_id                       = each.value.web_acl_id
  http_version                     = each.value.http_version
  is_ipv6_enabled                  = each.value.is_ipv6_enabled
  tags                             = merge(var.default_tags, each.value.tags)
}

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                   = each.value.name
  cidr_block             = each.value.cidr_block
  public_subnets         = each.value.public_subnets
  private_subnets        = each.value.private_subnets
  enable_dns_hostnames   = each.value.enable_dns_hostnames
  enable_dns_support     = each.value.enable_dns_support
  enable_nat_gateway     = each.value.enable_nat_gateway
  single_nat_gateway     = each.value.single_nat_gateway
  one_nat_gateway_per_az = each.value.one_nat_gateway_per_az
  create_public_nacl     = each.value.create_public_nacl
  create_private_nacl    = each.value.create_private_nacl
  tags                   = merge(var.default_tags, each.value.tags)
}

locals {
  alb_vpc_ids = {
    for name, alb in var.load_balancers : name => coalesce(
      try(alb.vpc_id, null),
      try(module.vpc[alb.vpc_key].vpc_id, null)
    )
  }

  alb_subnet_ids = {
    for name, alb in var.load_balancers : name => coalesce(
      try(alb.subnet_ids, null),
      try(values(module.vpc[alb.vpc_key].public_subnet_ids), null)
    )
  }

  security_group_vpc_ids = {
    for name, sg in var.security_groups : name => coalesce(
      try(sg.vpc_id, null),
      try(module.vpc[sg.vpc_key].vpc_id, null)
    )
  }

  nlb_vpc_ids = {
    for name, nlb in var.network_load_balancers : name => coalesce(
      try(nlb.vpc_id, null),
      try(module.vpc[nlb.vpc_key].vpc_id, null)
    )
  }

  nlb_subnet_ids = {
    for name, nlb in var.network_load_balancers : name => coalesce(
      try(nlb.subnet_ids, null),
      try(
        nlb.internal ? values(module.vpc[nlb.vpc_key].private_subnet_ids) : values(module.vpc[nlb.vpc_key].public_subnet_ids),
        null
      )
    )
  }

  codebuild_vpc_configs = {
    for name, project in var.codebuild_projects :
    name => try(project.vpc_config, null) != null ? project.vpc_config : (
      try(project.vpc_key, null) != null ? {
        vpc_id = coalesce(
          try(project.vpc_id, null),
          module.vpc[project.vpc_key].vpc_id
        )
        subnet_ids = coalesce(
          try(project.subnet_ids, null),
          values(module.vpc[project.vpc_key].private_subnet_ids)
        )
        security_group_ids = coalesce(
          length(try(project.security_group_ids, [])) > 0 ? project.security_group_ids : null,
          try(project.security_group_key, null) != null ? try([module.security_group[project.security_group_key].security_group_id], null) : null
        )
      } : null
    )
  }

  codepipeline_artifact_buckets = {
    for name, pipeline in var.codepipelines : name => coalesce(
      try(pipeline.artifact_bucket, null),
      try(module.s3[pipeline.artifact_bucket_key].bucket_id, null)
    )
  }

  codepipeline_kms_key_arns = {
    for name, pipeline in var.codepipelines : name => (
      try(pipeline.artifact_kms_key_arn, null) != null ? pipeline.artifact_kms_key_arn : (
        try(pipeline.artifact_kms_key_key, null) != null ? module.kms[pipeline.artifact_kms_key_key].key_arn : null
      )
    )
  }

  codepipeline_stages = {
    for name, pipeline in var.codepipelines : name => [
      for stage in pipeline.stages : {
        name = stage.name
        actions = [
          for action in stage.actions : {
            name             = action.name
            category         = action.category
            owner            = action.owner
            provider         = action.provider
            version          = action.version
            input_artifacts  = try(action.input_artifacts, [])
            output_artifacts = try(action.output_artifacts, [])
            role_arn         = try(action.role_arn, null)
            run_order        = try(action.run_order, null)
            namespace        = try(action.namespace, null)
            configuration = merge(
              try(action.configuration, {}),
              try(action.codebuild_project_key, null) != null ? {
                ProjectName = module.codebuild[action.codebuild_project_key].project_name
              } : {}
            )
          }
        ]
      }
    ]
  }

  ec2_subnet_ids = {
    for name, instance in var.ec2_instances : name => coalesce(
      try(instance.subnet_id, null),
      try(
        coalesce(try(instance.subnet_type, "private"), "private") == "private"
        ? module.vpc[instance.vpc_key].private_subnet_ids[instance.subnet_key]
        : module.vpc[instance.vpc_key].public_subnet_ids[instance.subnet_key],
        null
      )
    )
  }

  ec2_security_group_ids = {
    for name, instance in var.ec2_instances : name => coalesce(
      length(coalesce(try(instance.security_group_ids, null), [])) > 0 ? instance.security_group_ids : null,
      length([
        for key in coalesce(try(instance.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(instance.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : null
    )
  }

  ec2_iam_instance_profiles = {
    for name, instance in var.ec2_instances : name => coalesce(
      try(instance.iam_instance_profile, null),
      try(instance.iam_role_key, null) != null && contains(keys(var.iam_roles), instance.iam_role_key) ? (
        module.iam_role[instance.iam_role_key].instance_profile_name
      ) : null
    )
  }

  ec2_root_block_devices = {
    for name, instance in var.ec2_instances : name => (
      try(instance.root_block_device, null) != null ? {
        volume_size           = try(instance.root_block_device.volume_size, null)
        volume_type           = try(instance.root_block_device.volume_type, null)
        iops                  = try(instance.root_block_device.iops, null)
        throughput            = try(instance.root_block_device.throughput, null)
        encrypted             = try(instance.root_block_device.encrypted, null)
        kms_key_id = (
          try(instance.root_block_device.kms_key_id, null) != null ? instance.root_block_device.kms_key_id : (
            try(instance.root_block_device.kms_key_key, null) != null && contains(keys(var.kms_keys), instance.root_block_device.kms_key_key) ? (
              module.kms[instance.root_block_device.kms_key_key].key_arn
            ) : null
          )
        )
        delete_on_termination = try(instance.root_block_device.delete_on_termination, null)
      } : null
    )
  }

  ec2_ebs_block_devices = {
    for name, instance in var.ec2_instances : name => {
      for device_key, device in coalesce(try(instance.ebs_block_devices, {}), {}) : device_key => {
        device_name           = device.device_name
        volume_size           = try(device.volume_size, null)
        volume_type           = try(device.volume_type, "gp3")
        iops                  = try(device.iops, null)
        throughput            = try(device.throughput, null)
        encrypted             = try(device.encrypted, true)
        kms_key_id = (
          try(device.kms_key_id, null) != null ? device.kms_key_id : (
            try(device.kms_key_key, null) != null && contains(keys(var.kms_keys), device.kms_key_key) ? (
              module.kms[device.kms_key_key].key_arn
            ) : null
          )
        )
        delete_on_termination = try(device.delete_on_termination, true)
        snapshot_id           = try(device.snapshot_id, null)
      }
    }
  }

  rds_subnet_ids = {
    for name, db in var.rds_instances : name => coalesce(
      length(coalesce(try(db.subnet_ids, null), [])) > 0 ? db.subnet_ids : null,
      length([
        for key in coalesce(try(db.subnet_keys, null), []) :
        key if try(db.vpc_key, null) != null && contains(keys(var.vpcs), db.vpc_key)
      ]) > 0 ? [
        for key in coalesce(try(db.subnet_keys, null), []) :
        module.vpc[db.vpc_key].private_subnet_ids[key]
        if try(db.vpc_key, null) != null && contains(keys(var.vpcs), db.vpc_key) && contains(keys(var.vpcs[db.vpc_key].private_subnets), key)
      ] : null
    )
  }

  rds_security_group_ids = {
    for name, db in var.rds_instances : name => coalesce(
      length(coalesce(try(db.security_group_ids, null), [])) > 0 ? db.security_group_ids : null,
      length([
        for key in coalesce(try(db.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(db.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : null
    )
  }

  rds_kms_key_ids = {
    for name, db in var.rds_instances : name => (
      try(db.kms_key_id, null) != null ? db.kms_key_id : (
        try(db.kms_key_key, null) != null && contains(keys(var.kms_keys), db.kms_key_key) ? (
          module.kms[db.kms_key_key].key_arn
        ) : null
      )
    )
  }

  apigateway_integrations = {
    for api_name, api in var.api_gateways : api_name => {
      for int_key, integration in api.integrations : int_key => {
        integration_type       = integration.integration_type
        integration_method     = try(integration.integration_method, "POST")
        integration_uri = (
          try(integration.integration_uri, null) != null ? integration.integration_uri :
          try(integration.lambda_function_key, null) != null && contains(keys(var.lambda_functions), integration.lambda_function_key) ? (
            module.lambda[integration.lambda_function_key].invoke_arn
          ) :
          try(integration.load_balancer_key, null) != null && contains(keys(var.load_balancers), integration.load_balancer_key) ? (
            "https://${module.alb[integration.load_balancer_key].load_balancer_dns_name}"
          ) :
          null
        )
        connection_type        = try(integration.connection_type, "INTERNET")
        connection_id          = try(integration.connection_id, null)
        payload_format_version = try(integration.payload_format_version, null)
        timeout_milliseconds   = try(integration.timeout_milliseconds, 30000)
        credentials_arn        = try(integration.credentials_arn, null)
        request_parameters     = try(integration.request_parameters, {})
        lambda_function_name = (
          integration.integration_type == "AWS_PROXY" &&
          try(integration.lambda_function_key, null) != null &&
          contains(keys(var.lambda_functions), integration.lambda_function_key) ?
          module.lambda[integration.lambda_function_key].function_name :
          null
        )
        tls_config = try(integration.tls_config, null)
      }
    }
  }

  apigateway_authorizers = {
    for api_name, api in var.api_gateways : api_name => {
      for auth_key, authorizer in coalesce(try(api.authorizers, null), {}) : auth_key => {
        authorizer_type                   = authorizer.authorizer_type
        identity_sources                  = try(authorizer.identity_sources, [])
        name                              = try(authorizer.name, null)
        authorizer_uri = (
          try(authorizer.authorizer_uri, null) != null ? authorizer.authorizer_uri :
          try(authorizer.lambda_function_key, null) != null && contains(keys(var.lambda_functions), authorizer.lambda_function_key) ? (
            module.lambda[authorizer.lambda_function_key].invoke_arn
          ) :
          null
        )
        lambda_function_name = (
          authorizer.authorizer_type == "REQUEST" &&
          try(authorizer.lambda_function_key, null) != null &&
          contains(keys(var.lambda_functions), authorizer.lambda_function_key) ?
          module.lambda[authorizer.lambda_function_key].function_name :
          null
        )
        authorizer_payload_format_version = try(authorizer.authorizer_payload_format_version, null)
        authorizer_result_ttl_in_seconds  = try(authorizer.authorizer_result_ttl_in_seconds, null)
        enable_simple_responses           = try(authorizer.enable_simple_responses, null)
        jwt_configuration                 = try(authorizer.jwt_configuration, null)
      }
    }
  }

  apigateway_vpc_links = {
    for api_name, api in var.api_gateways : api_name => (
      try(api.vpc_link, null) != null ? {
        name = api.vpc_link.name
        subnet_ids = coalesce(
          length(coalesce(try(api.vpc_link.subnet_ids, null), [])) > 0 ? api.vpc_link.subnet_ids : null,
          length([
            for key in coalesce(try(api.vpc_link.subnet_keys, null), []) :
            key if try(api.vpc_link.vpc_key, null) != null && contains(keys(var.vpcs), api.vpc_link.vpc_key)
          ]) > 0 ? [
            for key in coalesce(try(api.vpc_link.subnet_keys, null), []) :
            module.vpc[api.vpc_link.vpc_key].private_subnet_ids[key]
            if try(api.vpc_link.vpc_key, null) != null && contains(keys(var.vpcs), api.vpc_link.vpc_key) && contains(keys(var.vpcs[api.vpc_link.vpc_key].private_subnets), key)
          ] : null
        )
        security_group_ids = coalesce(
          length(coalesce(try(api.vpc_link.security_group_ids, null), [])) > 0 ? api.vpc_link.security_group_ids : null,
          length([
            for key in coalesce(try(api.vpc_link.security_group_keys, null), []) :
            key if contains(keys(var.security_groups), key)
          ]) > 0 ? [
            for key in coalesce(try(api.vpc_link.security_group_keys, null), []) :
            module.security_group[key].security_group_id
            if contains(keys(var.security_groups), key)
          ] : null
        )
      } : null
    )
  }

  sns_kms_key_ids = {
    for name, topic in var.sns_topics : name => (
      try(topic.kms_key_id, null) != null ? topic.kms_key_id : (
        try(topic.kms_key_key, null) != null && contains(keys(var.kms_keys), topic.kms_key_key) ? (
          module.kms[topic.kms_key_key].key_arn
        ) : null
      )
    )
  }

  sns_subscriptions = {
    for topic_name, topic in var.sns_topics : topic_name => {
      for sub_key, subscription in coalesce(try(topic.subscriptions, null), {}) : sub_key => {
        protocol                        = subscription.protocol
        endpoint = (
          try(subscription.endpoint, null) != null ? subscription.endpoint :
          subscription.protocol == "lambda" &&
          try(subscription.lambda_function_key, null) != null &&
          contains(keys(var.lambda_functions), subscription.lambda_function_key) ?
          module.lambda[subscription.lambda_function_key].function_arn :
          null
        )
        lambda_function_name = (
          subscription.protocol == "lambda" &&
          try(subscription.lambda_function_key, null) != null &&
          contains(keys(var.lambda_functions), subscription.lambda_function_key) ?
          module.lambda[subscription.lambda_function_key].function_name :
          try(subscription.lambda_function_name, null)
        )
        endpoint_auto_confirms          = try(subscription.endpoint_auto_confirms, false)
        confirmation_timeout_in_minutes = try(subscription.confirmation_timeout_in_minutes, null)
        raw_message_delivery            = try(subscription.raw_message_delivery, false)
        filter_policy                   = try(subscription.filter_policy, null)
        filter_policy_scope             = try(subscription.filter_policy_scope, null)
        redrive_policy                  = try(subscription.redrive_policy, null)
        subscription_role_arn           = try(subscription.subscription_role_arn, null)
      }
    }
  }

  sqs_kms_key_ids = {
    for name, queue in var.sqs_queues : name => (
      try(queue.kms_key_id, null) != null ? queue.kms_key_id : (
        try(queue.kms_key_key, null) != null && contains(keys(var.kms_keys), queue.kms_key_key) ? (
          module.kms[queue.kms_key_key].key_arn
        ) : null
      )
    )
  }

  sqs_allowed_sns_topic_arns = {
    for name, queue in var.sqs_queues : name => [
      for key in coalesce(try(queue.sns_topic_keys, null), []) :
      module.sns[key].topic_arn
      if contains(keys(var.sns_topics), key)
    ]
  }

  eks_subnet_ids = {
    for name, cluster in var.eks_clusters : name => coalesce(
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 ? cluster.subnet_ids : null,
      length([
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        key if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        module.vpc[cluster.vpc_key].private_subnet_ids[key]
        if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key) && contains(keys(var.vpcs[cluster.vpc_key].private_subnets), key)
      ] : null
    )
  }

  eks_security_group_ids = {
    for name, cluster in var.eks_clusters : name => (
      length(coalesce(try(cluster.security_group_ids, null), [])) > 0 ? cluster.security_group_ids :
      length([
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : []
    )
  }

  eks_kms_key_arns = {
    for name, cluster in var.eks_clusters : name => (
      try(cluster.kms_key_id, null) != null ? cluster.kms_key_id : (
        try(cluster.kms_key_key, null) != null && contains(keys(var.kms_keys), cluster.kms_key_key) ? (
          module.kms[cluster.kms_key_key].key_arn
        ) : null
      )
    )
  }

  eks_cluster_role_arns = {
    for name, cluster in var.eks_clusters : name => (
      try(cluster.cluster_role_arn, null) != null ? cluster.cluster_role_arn : (
        try(cluster.cluster_role_key, null) != null && contains(keys(var.iam_roles), cluster.cluster_role_key) ? (
          module.iam_role[cluster.cluster_role_key].role_arn
        ) : null
      )
    )
  }

  eks_node_role_arns = {
    for name, cluster in var.eks_clusters : name => (
      try(cluster.node_role_arn, null) != null ? cluster.node_role_arn : (
        try(cluster.node_role_key, null) != null && contains(keys(var.iam_roles), cluster.node_role_key) ? (
          module.iam_role[cluster.node_role_key].role_arn
        ) : null
      )
    )
  }

  iam_role_managed_policy_key_arns = {
    for name, role in var.iam_roles : name => {
      for key in coalesce(try(role.managed_policy_keys, null), []) :
      key => module.iam_policy[key].policy_arn
      if contains(keys(var.iam_policies), key)
    }
  }

  iam_user_managed_policy_key_arns = {
    for name, user in var.iam_users : name => {
      for key in coalesce(try(user.managed_policy_keys, null), []) :
      key => module.iam_policy[key].policy_arn
      if contains(keys(var.iam_policies), key)
    }
  }

  iam_user_permissions_boundaries = {
    for name, user in var.iam_users : name => (
      try(user.permissions_boundary, null) != null ? user.permissions_boundary : (
        try(user.permissions_boundary_key, null) != null && contains(keys(var.iam_policies), user.permissions_boundary_key) ? (
          module.iam_policy[user.permissions_boundary_key].policy_arn
        ) : null
      )
    )
  }

  ecr_kms_key_ids = {
    for name, repo in var.ecr_repositories : name => (
      try(repo.kms_key_id, null) != null ? repo.kms_key_id : (
        try(repo.kms_key_key, null) != null && contains(keys(var.kms_keys), repo.kms_key_key) ? (
          module.kms[repo.kms_key_key].key_arn
        ) : null
      )
    )
  }

  ecs_subnet_ids = {
    for name, cluster in var.ecs_clusters : name => coalesce(
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 ? cluster.subnet_ids : null,
      length([
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        key if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        module.vpc[cluster.vpc_key].private_subnet_ids[key]
        if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key) && contains(keys(var.vpcs[cluster.vpc_key].private_subnets), key)
      ] : null,
      []
    )
  }

  ecs_security_group_ids = {
    for name, cluster in var.ecs_clusters : name => (
      length(coalesce(try(cluster.security_group_ids, null), [])) > 0 ? cluster.security_group_ids :
      length([
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : []
    )
  }

  ecs_execution_role_arns = {
    for name, cluster in var.ecs_clusters : name => (
      try(cluster.execution_role_arn, null) != null ? cluster.execution_role_arn : (
        try(cluster.execution_role_key, null) != null && contains(keys(var.iam_roles), cluster.execution_role_key) ? (
          module.iam_role[cluster.execution_role_key].role_arn
        ) : null
      )
    )
  }

  ecs_services = {
    for cluster_name, cluster in var.ecs_clusters : cluster_name => {
      for svc_name, svc in cluster.services : svc_name => merge(svc, {
        containers = {
          for cname, container in svc.containers : cname => merge(container, {
            image = (
              try(container.image, null) != null ? container.image :
              try(container.ecr_repository_key, null) != null && contains(keys(var.ecr_repositories), container.ecr_repository_key) ? (
                "${module.ecr[container.ecr_repository_key].repository_url}:${coalesce(try(container.image_tag, null), "latest")}"
              ) : null
            )
          })
        }
        execution_role_arn = (
          try(svc.execution_role_arn, null) != null ? svc.execution_role_arn :
          try(svc.execution_role_key, null) != null && contains(keys(var.iam_roles), svc.execution_role_key) ? (
            module.iam_role[svc.execution_role_key].role_arn
          ) : null
        )
        task_role_arn = (
          try(svc.task_role_arn, null) != null ? svc.task_role_arn :
          try(svc.task_role_key, null) != null && contains(keys(var.iam_roles), svc.task_role_key) ? (
            module.iam_role[svc.task_role_key].role_arn
          ) : null
        )
        subnet_ids = (
          length(coalesce(try(svc.subnet_ids, null), [])) > 0 ? svc.subnet_ids :
          local.ecs_subnet_ids[cluster_name]
        )
        security_group_ids = (
          length(coalesce(try(svc.security_group_ids, null), [])) > 0 ? svc.security_group_ids :
          local.ecs_security_group_ids[cluster_name]
        )
        load_balancers = concat(
          coalesce(try(svc.load_balancers, null), []),
          [
            for attachment in coalesce(try(svc.target_group_attachments, null), []) : {
              target_group_arn = module.alb[attachment.alb_key].target_group_arns[attachment.target_group_key]
              container_name   = attachment.container_name
              container_port   = attachment.container_port
            }
            if contains(keys(var.load_balancers), attachment.alb_key) && contains(keys(var.load_balancers[attachment.alb_key].target_groups), attachment.target_group_key)
          ]
        )
      })
    }
  }

  efs_subnet_ids = {
    for name, fs in var.efs_file_systems : name => coalesce(
      length(coalesce(try(fs.subnet_ids, null), [])) > 0 ? fs.subnet_ids : null,
      length([
        for key in coalesce(try(fs.subnet_keys, null), []) :
        key if try(fs.vpc_key, null) != null && contains(keys(var.vpcs), fs.vpc_key)
      ]) > 0 ? [
        for key in coalesce(try(fs.subnet_keys, null), []) :
        module.vpc[fs.vpc_key].private_subnet_ids[key]
        if try(fs.vpc_key, null) != null && contains(keys(var.vpcs), fs.vpc_key) && contains(keys(var.vpcs[fs.vpc_key].private_subnets), key)
      ] : null,
      []
    )
  }

  efs_security_group_ids = {
    for name, fs in var.efs_file_systems : name => (
      length(coalesce(try(fs.security_group_ids, null), [])) > 0 ? fs.security_group_ids :
      length([
        for key in coalesce(try(fs.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(fs.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : []
    )
  }

  efs_kms_key_ids = {
    for name, fs in var.efs_file_systems : name => (
      try(fs.kms_key_id, null) != null ? fs.kms_key_id : (
        try(fs.kms_key_key, null) != null && contains(keys(var.kms_keys), fs.kms_key_key) ? (
          module.kms[fs.kms_key_key].key_arn
        ) : null
      )
    )
  }

  cognito_lambda_configs = {
    for name, pool in var.cognito_user_pools : name => {
      pre_sign_up = (
        try(pool.lambda_config.pre_sign_up_arn, null) != null ? pool.lambda_config.pre_sign_up_arn :
        try(pool.lambda_config.pre_sign_up_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.pre_sign_up_key) ?
        module.lambda[pool.lambda_config.pre_sign_up_key].function_arn : null
      )
      custom_message = (
        try(pool.lambda_config.custom_message_arn, null) != null ? pool.lambda_config.custom_message_arn :
        try(pool.lambda_config.custom_message_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.custom_message_key) ?
        module.lambda[pool.lambda_config.custom_message_key].function_arn : null
      )
      post_confirmation = (
        try(pool.lambda_config.post_confirmation_arn, null) != null ? pool.lambda_config.post_confirmation_arn :
        try(pool.lambda_config.post_confirmation_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.post_confirmation_key) ?
        module.lambda[pool.lambda_config.post_confirmation_key].function_arn : null
      )
      pre_authentication = (
        try(pool.lambda_config.pre_authentication_arn, null) != null ? pool.lambda_config.pre_authentication_arn :
        try(pool.lambda_config.pre_authentication_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.pre_authentication_key) ?
        module.lambda[pool.lambda_config.pre_authentication_key].function_arn : null
      )
      post_authentication = (
        try(pool.lambda_config.post_authentication_arn, null) != null ? pool.lambda_config.post_authentication_arn :
        try(pool.lambda_config.post_authentication_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.post_authentication_key) ?
        module.lambda[pool.lambda_config.post_authentication_key].function_arn : null
      )
      define_auth_challenge = (
        try(pool.lambda_config.define_auth_challenge_arn, null) != null ? pool.lambda_config.define_auth_challenge_arn :
        try(pool.lambda_config.define_auth_challenge_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.define_auth_challenge_key) ?
        module.lambda[pool.lambda_config.define_auth_challenge_key].function_arn : null
      )
      create_auth_challenge = (
        try(pool.lambda_config.create_auth_challenge_arn, null) != null ? pool.lambda_config.create_auth_challenge_arn :
        try(pool.lambda_config.create_auth_challenge_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.create_auth_challenge_key) ?
        module.lambda[pool.lambda_config.create_auth_challenge_key].function_arn : null
      )
      verify_auth_challenge_response = (
        try(pool.lambda_config.verify_auth_challenge_response_arn, null) != null ? pool.lambda_config.verify_auth_challenge_response_arn :
        try(pool.lambda_config.verify_auth_challenge_response_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.verify_auth_challenge_response_key) ?
        module.lambda[pool.lambda_config.verify_auth_challenge_response_key].function_arn : null
      )
      user_migration = (
        try(pool.lambda_config.user_migration_arn, null) != null ? pool.lambda_config.user_migration_arn :
        try(pool.lambda_config.user_migration_key, null) != null && contains(keys(var.lambda_functions), pool.lambda_config.user_migration_key) ?
        module.lambda[pool.lambda_config.user_migration_key].function_arn : null
      )
    }
  }

  cognito_identity_pools = {
    for name, pool in var.cognito_user_pools : name => (
      try(pool.identity_pool, null) != null ? {
        name                             = pool.identity_pool.name
        client_key                       = pool.identity_pool.client_key
        allow_unauthenticated_identities = try(pool.identity_pool.allow_unauthenticated_identities, false)
        authenticated_role_arn = (
          try(pool.identity_pool.authenticated_role_arn, null) != null ? pool.identity_pool.authenticated_role_arn :
          try(pool.identity_pool.authenticated_role_key, null) != null && contains(keys(var.iam_roles), pool.identity_pool.authenticated_role_key) ?
          module.iam_role[pool.identity_pool.authenticated_role_key].role_arn : null
        )
        unauthenticated_role_arn = (
          try(pool.identity_pool.unauthenticated_role_arn, null) != null ? pool.identity_pool.unauthenticated_role_arn :
          try(pool.identity_pool.unauthenticated_role_key, null) != null && contains(keys(var.iam_roles), pool.identity_pool.unauthenticated_role_key) ?
          module.iam_role[pool.identity_pool.unauthenticated_role_key].role_arn : null
        )
      } : null
    )
  }

  msk_subnet_ids = {
    for name, cluster in var.msk_clusters : name => coalesce(
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 ? cluster.subnet_ids : null,
      length([
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        key if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        module.vpc[cluster.vpc_key].private_subnet_ids[key]
        if try(cluster.vpc_key, null) != null && contains(keys(var.vpcs), cluster.vpc_key) && contains(keys(var.vpcs[cluster.vpc_key].private_subnets), key)
      ] : null,
      []
    )
  }

  msk_security_group_ids = {
    for name, cluster in var.msk_clusters : name => (
      length(coalesce(try(cluster.security_group_ids, null), [])) > 0 ? cluster.security_group_ids :
      length([
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        key if contains(keys(var.security_groups), key)
      ]) > 0 ? [
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        module.security_group[key].security_group_id
        if contains(keys(var.security_groups), key)
      ] : []
    )
  }

  msk_kms_key_ids = {
    for name, cluster in var.msk_clusters : name => (
      try(cluster.kms_key_id, null) != null ? cluster.kms_key_id : (
        try(cluster.kms_key_key, null) != null && contains(keys(var.kms_keys), cluster.kms_key_key) ? (
          module.kms[cluster.kms_key_key].key_arn
        ) : null
      )
    )
  }

  msk_scram_secret_arns = {
    for name, cluster in var.msk_clusters : name => concat(
      coalesce(try(cluster.scram_secret_arns, null), []),
      [
        for key in coalesce(try(cluster.scram_secret_keys, null), []) :
        module.secrets_manager[key].secret_arn
        if contains(keys(var.secrets), key)
      ]
    )
  }

  msk_logging = {
    for name, cluster in var.msk_clusters : name => (
      try(cluster.logging, null) != null ? merge(cluster.logging, {
        s3 = try(cluster.logging.s3, null) != null ? merge(cluster.logging.s3, {
          bucket = coalesce(
            try(cluster.logging.s3.bucket, null),
            try(cluster.logging.s3.bucket_key, null) != null && contains(keys(var.buckets), cluster.logging.s3.bucket_key) ?
            module.s3[cluster.logging.s3.bucket_key].bucket_id : null
          )
        }) : null
      }) : null
    )
  }

  msk_effective_subnet_counts = {
    for name, cluster in var.msk_clusters : name => (
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 ? length(cluster.subnet_ids) :
      length([
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        key
        if try(cluster.vpc_key, null) != null &&
        contains(keys(var.vpcs), cluster.vpc_key) &&
        contains(keys(var.vpcs[cluster.vpc_key].private_subnets), key)
      ])
    )
  }
}

check "alb_vpc_reference" {
  assert {
    condition = length(var.load_balancers) == 0 || alltrue([
      for name, alb in var.load_balancers :
      (try(alb.vpc_id, null) != null && alb.vpc_id != "") || (
        try(alb.vpc_key, null) != null && contains(keys(var.vpcs), alb.vpc_key)
      )
    ])
    error_message = "Each load balancer requires vpc_id or a valid vpc_key that exists in vpcs."
  }
}

module "alb" {
  source = "../../modules/alb"

  for_each = var.load_balancers

  depends_on = [module.vpc]

  name                       = each.value.name
  vpc_id                     = local.alb_vpc_ids[each.key]
  subnet_ids                 = local.alb_subnet_ids[each.key]
  internal                   = each.value.internal
  ip_address_type            = each.value.ip_address_type
  create_security_group      = each.value.create_security_group
  security_group_ids         = each.value.security_group_ids
  allowed_ingress_cidrs      = each.value.allowed_ingress_cidrs
  enable_deletion_protection = each.value.enable_deletion_protection
  idle_timeout               = each.value.idle_timeout
  drop_invalid_header_fields = each.value.drop_invalid_header_fields
  enable_http2               = each.value.enable_http2
  access_logs                = each.value.access_logs
  target_groups              = each.value.target_groups
  listeners                  = each.value.listeners
  tags                       = merge(var.default_tags, each.value.tags)
}

check "security_group_vpc_reference" {
  assert {
    condition = length(var.security_groups) == 0 || alltrue([
      for name, sg in var.security_groups :
      (try(sg.vpc_id, null) != null && sg.vpc_id != "") || (
        try(sg.vpc_key, null) != null && contains(keys(var.vpcs), sg.vpc_key)
      )
    ])
    error_message = "Each security group requires vpc_id or a valid vpc_key that exists in vpcs."
  }
}

module "security_group" {
  source = "../../modules/security-group"

  for_each = var.security_groups

  depends_on = [module.vpc]

  name                   = each.value.name
  vpc_id                 = local.security_group_vpc_ids[each.key]
  description            = each.value.description
  revoke_rules_on_delete = each.value.revoke_rules_on_delete
  ingress_rules          = each.value.ingress_rules
  egress_rules           = each.value.egress_rules
  tags                   = merge(var.default_tags, each.value.tags)
}

check "nlb_vpc_reference" {
  assert {
    condition = length(var.network_load_balancers) == 0 || alltrue([
      for name, nlb in var.network_load_balancers :
      (try(nlb.vpc_id, null) != null && nlb.vpc_id != "") || (
        try(nlb.vpc_key, null) != null && contains(keys(var.vpcs), nlb.vpc_key)
      )
    ])
    error_message = "Each network load balancer requires vpc_id or a valid vpc_key that exists in vpcs."
  }
}

module "nlb" {
  source = "../../modules/nlb"

  for_each = var.network_load_balancers

  depends_on = [module.vpc]

  name                             = each.value.name
  vpc_id                           = local.nlb_vpc_ids[each.key]
  subnet_ids                       = local.nlb_subnet_ids[each.key]
  internal                         = each.value.internal
  ip_address_type                  = each.value.ip_address_type
  security_group_ids               = each.value.security_group_ids
  enable_deletion_protection       = each.value.enable_deletion_protection
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing
  access_logs                      = each.value.access_logs
  subnet_mappings                  = each.value.subnet_mappings
  target_groups                    = each.value.target_groups
  listeners                        = each.value.listeners
  tags                             = merge(var.default_tags, each.value.tags)
}

check "codebuild_vpc_reference" {
  assert {
    condition = length(var.codebuild_projects) == 0 || alltrue([
      for name, project in var.codebuild_projects :
      try(project.vpc_config, null) != null || try(project.vpc_key, null) == null || (
        try(project.vpc_id, null) != null && project.vpc_id != ""
      ) || contains(keys(var.vpcs), project.vpc_key)
    ])
    error_message = "Each CodeBuild project with vpc_key requires a valid vpc_key in vpcs or an explicit vpc_id."
  }
}

check "codebuild_security_group_reference" {
  assert {
    condition = length(var.codebuild_projects) == 0 || alltrue([
      for name, project in var.codebuild_projects :
      try(project.security_group_key, null) == null || contains(keys(var.security_groups), project.security_group_key)
    ])
    error_message = "Each CodeBuild project security_group_key must exist in security_groups."
  }
}

check "codebuild_vpc_security_groups" {
  assert {
    condition = length(var.codebuild_projects) == 0 || alltrue([
      for name, project in var.codebuild_projects :
      local.codebuild_vpc_configs[name] == null || (
        try(local.codebuild_vpc_configs[name].security_group_ids, null) != null &&
        length(local.codebuild_vpc_configs[name].security_group_ids) > 0
      )
    ])
    error_message = "CodeBuild projects in a VPC require security_group_ids or a valid security_group_key."
  }
}

module "codebuild" {
  source = "../../modules/codebuild"

  for_each = var.codebuild_projects

  depends_on = [module.vpc, module.security_group]

  name                   = each.value.name
  description            = each.value.description
  build_timeout          = each.value.build_timeout
  queued_timeout         = each.value.queued_timeout
  concurrent_build_limit = each.value.concurrent_build_limit
  badge_enabled          = each.value.badge_enabled
  encryption_key         = each.value.encryption_key
  create_service_role    = each.value.create_service_role
  service_role_arn       = each.value.service_role_arn
  role_name              = each.value.role_name
  managed_policy_arns    = each.value.managed_policy_arns
  policy_statements      = each.value.policy_statements
  create_log_group       = each.value.create_log_group
  log_retention_in_days  = each.value.log_retention_in_days
  buildspec              = each.value.buildspec
  source_version         = each.value.source_version
  source_config            = each.value.source
  artifacts              = each.value.artifacts
  cache                  = each.value.cache
  environment            = each.value.environment
  logs_config            = each.value.logs_config
  vpc_config             = local.codebuild_vpc_configs[each.key]
  webhook                = each.value.webhook
  file_system_locations  = each.value.file_system_locations
  tags                   = merge(var.default_tags, each.value.tags)
}

check "codepipeline_artifact_bucket" {
  assert {
    condition = length(var.codepipelines) == 0 || alltrue([
      for name, pipeline in var.codepipelines :
      (try(pipeline.artifact_bucket, null) != null && pipeline.artifact_bucket != "") || (
        try(pipeline.artifact_bucket_key, null) != null && contains(keys(var.buckets), pipeline.artifact_bucket_key)
      )
    ])
    error_message = "Each CodePipeline requires artifact_bucket or a valid artifact_bucket_key in buckets."
  }
}

check "codepipeline_kms_key_reference" {
  assert {
    condition = length(var.codepipelines) == 0 || alltrue([
      for name, pipeline in var.codepipelines :
      try(pipeline.artifact_kms_key_key, null) == null || contains(keys(var.kms_keys), pipeline.artifact_kms_key_key)
    ])
    error_message = "Each CodePipeline artifact_kms_key_key must exist in kms_keys."
  }
}

check "codepipeline_codebuild_reference" {
  assert {
    condition = length(var.codepipelines) == 0 || alltrue(flatten([
      for name, pipeline in var.codepipelines : [
        for stage in pipeline.stages : [
          for action in stage.actions :
          try(action.codebuild_project_key, null) == null || contains(keys(var.codebuild_projects), action.codebuild_project_key)
        ]
      ]
    ]))
    error_message = "Each CodePipeline codebuild_project_key must exist in codebuild_projects."
  }
}

module "codepipeline" {
  source = "../../modules/codepipeline"

  for_each = var.codepipelines

  depends_on = [module.s3, module.kms, module.codebuild]

  name                      = each.value.name
  pipeline_type             = each.value.pipeline_type
  execution_mode            = each.value.execution_mode
  artifact_bucket           = local.codepipeline_artifact_buckets[each.key]
  artifact_kms_key_arn      = local.codepipeline_kms_key_arns[each.key]
  artifact_store_region     = each.value.artifact_store_region
  secondary_artifact_stores = each.value.secondary_artifact_stores
  create_service_role       = each.value.create_service_role
  service_role_arn          = each.value.service_role_arn
  role_name                 = each.value.role_name
  managed_policy_arns       = each.value.managed_policy_arns
  policy_statements         = each.value.policy_statements
  stages                    = local.codepipeline_stages[each.key]
  trigger                   = each.value.trigger
  variables                 = each.value.variables
  tags                      = merge(var.default_tags, each.value.tags)
}

module "iam_policy" {
  source = "../../modules/iam-policy"

  for_each = var.iam_policies

  name              = try(each.value.name, null)
  name_prefix       = try(each.value.name_prefix, null)
  description       = each.value.description
  path              = each.value.path
  policy_json       = each.value.policy_json
  policy_statements = each.value.policy_statements
  tags              = merge(var.default_tags, each.value.tags)
}

module "iam_role" {
  source = "../../modules/iam-role"

  for_each = var.iam_roles

  name                    = each.value.name
  description             = each.value.description
  path                    = each.value.path
  max_session_duration    = each.value.max_session_duration
  permissions_boundary    = each.value.permissions_boundary
  force_detach_policies   = each.value.force_detach_policies
  assume_role_policy_json = each.value.assume_role_policy_json
  trust_services          = each.value.trust_services
  trust_principals        = each.value.trust_principals
  assume_role_actions     = each.value.assume_role_actions
  assume_role_conditions  = each.value.assume_role_conditions
  managed_policy_arns     = coalesce(try(each.value.managed_policy_arns, null), [])
  managed_policy_key_arns = local.iam_role_managed_policy_key_arns[each.key]
  policy_statements       = each.value.policy_statements
  inline_policies         = each.value.inline_policies
  create_instance_profile = each.value.create_instance_profile
  instance_profile_name   = each.value.instance_profile_name
  tags                    = merge(var.default_tags, each.value.tags)

  depends_on = [module.iam_policy]
}

module "iam_user" {
  source = "../../modules/iam-user"

  for_each = var.iam_users

  name                    = each.value.name
  path                    = each.value.path
  permissions_boundary    = local.iam_user_permissions_boundaries[each.key]
  force_destroy           = each.value.force_destroy
  managed_policy_arns     = coalesce(try(each.value.managed_policy_arns, null), [])
  managed_policy_key_arns = local.iam_user_managed_policy_key_arns[each.key]
  policy_statements       = each.value.policy_statements
  inline_policies         = each.value.inline_policies
  create_access_key       = each.value.create_access_key
  access_key_status       = each.value.access_key_status
  access_key_pgp_key      = each.value.access_key_pgp_key
  create_login_profile    = each.value.create_login_profile
  login_profile_password_reset_required = each.value.login_profile_password_reset_required
  login_profile_password_length         = each.value.login_profile_password_length
  login_profile_pgp_key                 = each.value.login_profile_pgp_key
  tags                    = merge(var.default_tags, each.value.tags)

  depends_on = [module.iam_policy]
}

check "iam_user_managed_policy_keys" {
  assert {
    condition = length(var.iam_users) == 0 || alltrue([
      for name, user in var.iam_users : alltrue([
        for key in coalesce(try(user.managed_policy_keys, null), []) :
        contains(keys(var.iam_policies), key)
      ])
    ])
    error_message = "Each IAM user managed_policy_key must exist in iam_policies."
  }
}

check "iam_user_permissions_boundary_keys" {
  assert {
    condition = length(var.iam_users) == 0 || alltrue([
      for name, user in var.iam_users :
      try(user.permissions_boundary_key, null) == null || contains(keys(var.iam_policies), user.permissions_boundary_key)
    ])
    error_message = "Each IAM user permissions_boundary_key must exist in iam_policies."
  }
}

check "iam_user_permissions_boundary_source_exclusive" {
  assert {
    condition = length(var.iam_users) == 0 || alltrue([
      for name, user in var.iam_users :
      try(user.permissions_boundary, null) == null || try(user.permissions_boundary_key, null) == null
    ])
    error_message = "Each IAM user must use permissions_boundary or permissions_boundary_key, not both."
  }
}

check "iam_policy_name_exclusive" {
  assert {
    condition = length(var.iam_policies) == 0 || alltrue([
      for name, policy in var.iam_policies :
      (try(policy.name, null) != null) != (try(policy.name_prefix, null) != null)
    ])
    error_message = "Each IAM policy must set exactly one of name or name_prefix."
  }
}

check "iam_policy_policy_required" {
  assert {
    condition = length(var.iam_policies) == 0 || alltrue([
      for name, policy in var.iam_policies :
      try(policy.policy_json, null) != null || length(coalesce(try(policy.policy_statements, null), [])) > 0
    ])
    error_message = "Each IAM policy must define policy_json or policy_statements."
  }
}

check "iam_policy_policy_source_exclusive" {
  assert {
    condition = length(var.iam_policies) == 0 || alltrue([
      for name, policy in var.iam_policies :
      try(policy.policy_json, null) == null || length(coalesce(try(policy.policy_statements, null), [])) == 0
    ])
    error_message = "Each IAM policy cannot combine policy_json with policy_statements."
  }
}

check "iam_role_managed_policy_keys" {
  assert {
    condition = length(var.iam_roles) == 0 || alltrue([
      for name, role in var.iam_roles : alltrue([
        for key in coalesce(try(role.managed_policy_keys, null), []) :
        contains(keys(var.iam_policies), key)
      ])
    ])
    error_message = "Each IAM role managed_policy_key must exist in iam_policies."
  }
}

check "ec2_subnet_reference" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      (try(instance.subnet_id, null) != null && instance.subnet_id != "") || (
        try(instance.vpc_key, null) != null &&
        contains(keys(var.vpcs), instance.vpc_key) &&
        try(instance.subnet_key, null) != null &&
        (
          coalesce(try(instance.subnet_type, "private"), "private") == "private"
          ? contains(keys(var.vpcs[instance.vpc_key].private_subnets), instance.subnet_key)
          : contains(keys(var.vpcs[instance.vpc_key].public_subnets), instance.subnet_key)
        )
      )
    ])
    error_message = "Each EC2 instance requires subnet_id or a valid vpc_key + subnet_key (+ optional subnet_type)."
  }
}

check "ec2_subnet_type_values" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      try(instance.subnet_id, null) != null ||
      contains(["public", "private"], coalesce(try(instance.subnet_type, "private"), "private"))
    ])
    error_message = "subnet_type must be public or private when using vpc_key wiring."
  }
}

check "ec2_ami_source" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      try(instance.ami, null) != null || try(instance.ami_lookup, null) != null
    ])
    error_message = "Each EC2 instance requires ami or ami_lookup."
  }
}

check "ec2_eip_public_subnet" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      !try(instance.create_eip, false) ||
      try(instance.subnet_id, null) != null ||
      coalesce(try(instance.subnet_type, "private"), "private") == "public"
    ])
    error_message = "create_eip requires subnet_type = public when using vpc_key/subnet_key wiring."
  }
}

check "ec2_security_group_reference" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      length(coalesce(try(instance.security_group_ids, null), [])) > 0 || (
        length(coalesce(try(instance.security_group_keys, null), [])) > 0 &&
        alltrue([
          for key in instance.security_group_keys :
          contains(keys(var.security_groups), key)
        ])
      )
    ])
    error_message = "Each EC2 instance requires security_group_ids or valid security_group_keys."
  }
}

check "ec2_iam_role_reference" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      try(instance.iam_role_key, null) == null || (
        contains(keys(var.iam_roles), instance.iam_role_key) &&
        try(var.iam_roles[instance.iam_role_key].create_instance_profile, false)
      )
    ])
    error_message = "Each EC2 instance iam_role_key must reference an iam_roles entry with create_instance_profile = true."
  }
}

check "ec2_kms_key_reference" {
  assert {
    condition = length(var.ec2_instances) == 0 || alltrue([
      for name, instance in var.ec2_instances :
      (
        try(instance.root_block_device, null) == null ||
        try(instance.root_block_device.kms_key_key, null) == null ||
        contains(keys(var.kms_keys), instance.root_block_device.kms_key_key)
      ) && alltrue([
        for device in coalesce(try(instance.ebs_block_devices, {}), {}) :
        try(device.kms_key_key, null) == null || contains(keys(var.kms_keys), device.kms_key_key)
      ])
    ])
    error_message = "Each EC2 instance kms_key_key must exist in kms_keys."
  }
}

module "ec2" {
  source = "../../modules/ec2"

  for_each = var.ec2_instances

  depends_on = [module.vpc, module.security_group, module.iam_role, module.kms]

  name                               = each.value.name
  ami                                = try(each.value.ami, null)
  ami_lookup                         = try(each.value.ami_lookup, null)
  instance_type                      = each.value.instance_type
  subnet_id                          = local.ec2_subnet_ids[each.key]
  vpc_security_group_ids             = local.ec2_security_group_ids[each.key]
  key_name                           = try(each.value.key_name, null)
  iam_instance_profile               = local.ec2_iam_instance_profiles[each.key]
  availability_zone                  = try(each.value.availability_zone, null)
  associate_public_ip_address        = try(each.value.associate_public_ip_address, null)
  private_ip                         = try(each.value.private_ip, null)
  secondary_private_ips              = try(each.value.secondary_private_ips, [])
  source_dest_check                  = try(each.value.source_dest_check, null)
  user_data                          = try(each.value.user_data, null)
  user_data_base64                   = try(each.value.user_data_base64, null)
  user_data_replace_on_change        = try(each.value.user_data_replace_on_change, false)
  monitoring                         = try(each.value.monitoring, false)
  ebs_optimized                      = try(each.value.ebs_optimized, null)
  disable_api_termination            = try(each.value.disable_api_termination, false)
  instance_initiated_shutdown_behavior = try(each.value.instance_initiated_shutdown_behavior, null)
  tenancy                            = try(each.value.tenancy, "default")
  placement_group                    = try(each.value.placement_group, null)
  hibernation                        = try(each.value.hibernation, false)
  root_block_device                  = local.ec2_root_block_devices[each.key]
  ebs_block_devices                  = local.ec2_ebs_block_devices[each.key]
  metadata_options                   = try(each.value.metadata_options, null)
  cpu_options                        = try(each.value.cpu_options, null)
  credit_specification               = try(each.value.credit_specification, null)
  create_eip           = try(each.value.create_eip, false)
  eip_domain             = try(each.value.eip_domain, "vpc")
  ignore_ami_changes     = try(each.value.ignore_ami_changes, false)
  volume_tags            = try(each.value.volume_tags, {})
  tags                   = merge(var.default_tags, each.value.tags)
}

check "rds_subnet_reference" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      (
        !try(db.create_db_subnet_group, true) &&
        try(db.db_subnet_group_name, null) != null &&
        db.db_subnet_group_name != ""
      ) || (
        length(coalesce(try(db.subnet_ids, null), [])) >= 2
      ) || (
        try(db.vpc_key, null) != null &&
        contains(keys(var.vpcs), db.vpc_key) &&
        length(coalesce(try(db.subnet_keys, null), [])) >= 2 &&
        alltrue([
          for key in db.subnet_keys :
          contains(keys(var.vpcs[db.vpc_key].private_subnets), key)
        ])
      )
    ])
    error_message = "Each RDS instance requires two subnet_ids, two private subnet_keys with vpc_key, or an existing db_subnet_group_name."
  }
}

check "rds_subnet_az_coverage" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      !try(db.create_db_subnet_group, true) ||
      length(coalesce(try(db.subnet_ids, null), [])) >= 2 ||
      length(distinct([
        for key in coalesce(try(db.subnet_keys, null), []) :
        var.vpcs[db.vpc_key].private_subnets[key].availability_zone
        if try(db.vpc_key, null) != null &&
        contains(keys(var.vpcs), db.vpc_key) &&
        contains(keys(var.vpcs[db.vpc_key].private_subnets), key)
      ])) >= 2
    ])
    error_message = "RDS subnet_keys must span at least two availability zones."
  }
}

check "rds_security_group_reference" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      length(coalesce(try(db.security_group_ids, null), [])) > 0 || (
        length(coalesce(try(db.security_group_keys, null), [])) > 0 &&
        alltrue([
          for key in db.security_group_keys :
          contains(keys(var.security_groups), key)
        ])
      )
    ])
    error_message = "Each RDS instance requires security_group_ids or valid security_group_keys."
  }
}

check "rds_kms_key_reference" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      try(db.kms_key_key, null) == null || contains(keys(var.kms_keys), db.kms_key_key)
    ])
    error_message = "Each RDS instance kms_key_key must exist in kms_keys."
  }
}

check "rds_engine_version_source" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      (
        (try(db.engine_version, null) != null ? 1 : 0) +
        (try(db.engine_version_lookup, null) != null ? 1 : 0)
      ) == 1
    ])
    error_message = "Each RDS instance requires exactly one of engine_version or engine_version_lookup."
  }
}

check "rds_password_source" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      (
        (try(db.password, null) != null ? 1 : 0) +
        (try(db.manage_master_user_password, false) ? 1 : 0) +
        (try(db.generate_password, null) != null ? 1 : 0)
      ) == 1
    ])
    error_message = "Each RDS instance requires exactly one of password, manage_master_user_password, or generate_password."
  }
}

check "rds_parameter_group_family" {
  assert {
    condition = length(var.rds_instances) == 0 || alltrue([
      for name, db in var.rds_instances :
      !try(db.create_parameter_group, false) || try(db.parameter_group_family, null) != null
    ])
    error_message = "parameter_group_family is required when create_parameter_group is true."
  }
}

module "rds" {
  source = "../../modules/rds"

  for_each = var.rds_instances

  depends_on = [module.vpc, module.security_group, module.kms]

  identifier        = each.value.identifier
  engine            = each.value.engine
  engine_version    = try(each.value.engine_version, null)
  engine_version_lookup = try(each.value.engine_version_lookup, null)
  instance_class    = each.value.instance_class
  allocated_storage = each.value.allocated_storage
  username          = each.value.username
  password          = try(each.value.password, null)
  manage_master_user_password = try(each.value.manage_master_user_password, false)
  generate_password = try(each.value.generate_password, null)
  max_allocated_storage = try(each.value.max_allocated_storage, 0)
  storage_type          = try(each.value.storage_type, "gp3")
  iops                  = try(each.value.iops, null)
  storage_throughput    = try(each.value.storage_throughput, null)
  db_name               = try(each.value.db_name, null)
  port                  = try(each.value.port, null)
  subnet_ids            = coalesce(local.rds_subnet_ids[each.key], [])
  vpc_security_group_ids = local.rds_security_group_ids[each.key]
  db_subnet_group_name  = try(each.value.db_subnet_group_name, null)
  create_db_subnet_group = try(each.value.create_db_subnet_group, true)
  parameter_group_name  = try(each.value.parameter_group_name, null)
  create_parameter_group = try(each.value.create_parameter_group, false)
  parameter_group_family = try(each.value.parameter_group_family, null)
  parameters            = try(each.value.parameters, [])
  multi_az              = try(each.value.multi_az, false)
  publicly_accessible   = try(each.value.publicly_accessible, false)
  storage_encrypted     = try(each.value.storage_encrypted, true)
  kms_key_id            = local.rds_kms_key_ids[each.key]
  backup_retention_period = try(each.value.backup_retention_period, 7)
  backup_window           = try(each.value.backup_window, null)
  maintenance_window    = try(each.value.maintenance_window, null)
  deletion_protection   = try(each.value.deletion_protection, true)
  skip_final_snapshot   = try(each.value.skip_final_snapshot, false)
  final_snapshot_identifier = try(each.value.final_snapshot_identifier, null)
  apply_immediately     = try(each.value.apply_immediately, false)
  auto_minor_version_upgrade = try(each.value.auto_minor_version_upgrade, true)
  monitoring_interval   = try(each.value.monitoring_interval, 0)
  monitoring_role_arn   = try(each.value.monitoring_role_arn, null)
  enabled_cloudwatch_logs_exports = try(each.value.enabled_cloudwatch_logs_exports, [])
  performance_insights_enabled = try(each.value.performance_insights_enabled, false)
  performance_insights_kms_key_id = try(each.value.performance_insights_kms_key_id, null)
  performance_insights_retention_period = try(each.value.performance_insights_retention_period, null)
  copy_tags_to_snapshot = try(each.value.copy_tags_to_snapshot, true)
  iam_database_authentication_enabled = try(each.value.iam_database_authentication_enabled, false)
  ca_cert_identifier    = try(each.value.ca_cert_identifier, null)
  tags                  = merge(var.default_tags, each.value.tags)
}

check "apigateway_lambda_function_keys" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways : alltrue([
        for int_key, integration in api.integrations :
        try(integration.lambda_function_key, null) == null || contains(keys(var.lambda_functions), integration.lambda_function_key)
      ])
    ])
    error_message = "Each API Gateway integration lambda_function_key must exist in lambda_functions."
  }
}

check "apigateway_load_balancer_keys" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways : alltrue([
        for int_key, integration in api.integrations :
        try(integration.load_balancer_key, null) == null || contains(keys(var.load_balancers), integration.load_balancer_key)
      ])
    ])
    error_message = "Each API Gateway integration load_balancer_key must exist in load_balancers."
  }
}

check "apigateway_authorizer_lambda_keys" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways : alltrue([
        for auth_key, authorizer in coalesce(try(api.authorizers, null), {}) :
        try(authorizer.lambda_function_key, null) == null || contains(keys(var.lambda_functions), authorizer.lambda_function_key)
      ])
    ])
    error_message = "Each API Gateway authorizer lambda_function_key must exist in lambda_functions."
  }
}

check "apigateway_vpc_link_wiring" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways :
      try(api.vpc_link, null) == null || (
        length(coalesce(try(api.vpc_link.subnet_ids, null), [])) > 0 || (
          try(api.vpc_link.vpc_key, null) != null &&
          contains(keys(var.vpcs), api.vpc_link.vpc_key) &&
          length(coalesce(try(api.vpc_link.subnet_keys, null), [])) > 0
        )
      )
    ])
    error_message = "API Gateway vpc_link requires subnet_ids or vpc_key with subnet_keys."
  }
}

check "apigateway_domain_stage_key" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways :
      try(api.domain, null) == null || contains(keys(api.stages), api.domain.stage_key)
    ])
    error_message = "API Gateway domain.stage_key must reference a defined stage."
  }
}

check "apigateway_integration_uri_resolved" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways : alltrue([
        for int_key, integration in api.integrations :
        integration.integration_type == "MOCK" || (
          try(integration.integration_uri, null) != null ||
          try(integration.lambda_function_key, null) != null ||
          try(integration.load_balancer_key, null) != null
        )
      ])
    ])
    error_message = "Non-MOCK integrations require integration_uri, lambda_function_key, or load_balancer_key."
  }
}

check "apigateway_api_key_routes" {
  assert {
    condition = length(var.api_gateways) == 0 || alltrue([
      for api_name, api in var.api_gateways : alltrue([
        for route_key, route in api.routes :
        !route.api_key_required || length(coalesce(try(api.api_keys, null), {})) > 0
      ])
    ])
    error_message = "Routes with api_key_required require at least one api_keys entry."
  }
}

module "apigateway" {
  source = "../../modules/apigateway"

  for_each = var.api_gateways

  depends_on = [module.lambda, module.alb, module.vpc, module.security_group]

  name                         = each.value.name
  description                  = try(each.value.description, null)
  protocol_type                = try(each.value.protocol_type, "HTTP")
  disable_execute_api_endpoint = try(each.value.disable_execute_api_endpoint, false)
  cors_configuration           = try(each.value.cors_configuration, null)
  integrations                 = local.apigateway_integrations[each.key]
  routes                       = each.value.routes
  authorizers                  = local.apigateway_authorizers[each.key]
  stages                       = each.value.stages
  domain                       = try(each.value.domain, null)
  vpc_link                     = local.apigateway_vpc_links[each.key]
  api_keys                     = coalesce(try(each.value.api_keys, null), {})
  tags                         = merge(var.default_tags, each.value.tags)
}

check "sns_lambda_function_keys" {
  assert {
    condition = length(var.sns_topics) == 0 || alltrue([
      for topic_name, topic in var.sns_topics : alltrue([
        for sub_key, subscription in coalesce(try(topic.subscriptions, null), {}) :
        try(subscription.lambda_function_key, null) == null || contains(keys(var.lambda_functions), subscription.lambda_function_key)
      ])
    ])
    error_message = "Each SNS subscription lambda_function_key must exist in lambda_functions."
  }
}

check "sns_kms_key_keys" {
  assert {
    condition = length(var.sns_topics) == 0 || alltrue([
      for topic_name, topic in var.sns_topics :
      try(topic.kms_key_key, null) == null || contains(keys(var.kms_keys), topic.kms_key_key)
    ])
    error_message = "Each SNS topic kms_key_key must exist in kms_keys."
  }
}

check "sns_subscription_endpoints" {
  assert {
    condition = length(var.sns_topics) == 0 || alltrue([
      for topic_name, topic in var.sns_topics : alltrue([
        for sub_key, subscription in coalesce(try(topic.subscriptions, null), {}) :
        try(subscription.endpoint, null) != null || (
          subscription.protocol == "lambda" && try(subscription.lambda_function_key, null) != null
        )
      ])
    ])
    error_message = "Non-lambda SNS subscriptions require endpoint; lambda subscriptions require lambda_function_key."
  }
}

check "sns_fifo_name_suffix" {
  assert {
    condition = length(var.sns_topics) == 0 || alltrue([
      for topic_name, topic in var.sns_topics :
      try(topic.name, null) == null || (
        try(topic.fifo_topic, false) == endswith(topic.name, ".fifo")
      )
    ])
    error_message = "FIFO SNS topics require a name ending with .fifo; standard topics must not use the .fifo suffix."
  }
}

check "sns_name_exclusive" {
  assert {
    condition = length(var.sns_topics) == 0 || alltrue([
      for topic_name, topic in var.sns_topics :
      (try(topic.name, null) != null) != (try(topic.name_prefix, null) != null)
    ])
    error_message = "Each SNS topic requires exactly one of name or name_prefix."
  }
}

module "sns" {
  source = "../../modules/sns"

  for_each = var.sns_topics

  depends_on = [module.lambda, module.kms]

  name                        = try(each.value.name, null)
  name_prefix                 = try(each.value.name_prefix, null)
  display_name                = try(each.value.display_name, null)
  fifo_topic                  = try(each.value.fifo_topic, false)
  content_based_deduplication = try(each.value.content_based_deduplication, false)
  fifo_throughput_scope       = try(each.value.fifo_throughput_scope, null)
  kms_key_id                  = local.sns_kms_key_ids[each.key]
  delivery_policy             = try(each.value.delivery_policy, null)
  archive_policy              = try(each.value.archive_policy, null)
  policy_json                 = try(each.value.policy_json, null)
  policy_statements           = try(each.value.policy_statements, [])
  subscriptions               = local.sns_subscriptions[each.key]
  tags                        = merge(var.default_tags, each.value.tags)
}

check "sqs_kms_key_keys" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues :
      try(queue.kms_key_key, null) == null || contains(keys(var.kms_keys), queue.kms_key_key)
    ])
    error_message = "Each SQS queue kms_key_key must exist in kms_keys."
  }
}

check "sqs_sns_topic_keys" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues : alltrue([
        for key in coalesce(try(queue.sns_topic_keys, null), []) :
        contains(keys(var.sns_topics), key)
      ])
    ])
    error_message = "Each SQS queue sns_topic_key must exist in sns_topics."
  }
}

check "sqs_fifo_name_suffix" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues :
      try(queue.name, null) == null || (
        try(queue.fifo_queue, false) == endswith(queue.name, ".fifo")
      )
    ])
    error_message = "FIFO SQS queues require a name ending with .fifo; standard queues must not use the .fifo suffix."
  }
}

check "sqs_name_exclusive" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues :
      (try(queue.name, null) != null) != (try(queue.name_prefix, null) != null)
    ])
    error_message = "Each SQS queue requires exactly one of name or name_prefix."
  }
}

check "sqs_redrive_exclusive" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues :
      try(queue.redrive_policy, null) == null || !try(queue.create_dlq, false)
    ])
    error_message = "SQS queues cannot set both redrive_policy and create_dlq."
  }
}

check "sqs_policy_json_sns_exclusive" {
  assert {
    condition = length(var.sqs_queues) == 0 || alltrue([
      for name, queue in var.sqs_queues :
      try(queue.policy_json, null) == null || length(coalesce(try(queue.sns_topic_keys, null), [])) == 0
    ])
    error_message = "SQS queues cannot combine policy_json with sns_topic_keys."
  }
}

module "sqs" {
  source = "../../modules/sqs"

  for_each = var.sqs_queues

  depends_on = [module.kms, module.sns]

  name                        = try(each.value.name, null)
  name_prefix                 = try(each.value.name_prefix, null)
  fifo_queue                  = try(each.value.fifo_queue, false)
  content_based_deduplication = try(each.value.content_based_deduplication, false)
  deduplication_scope         = try(each.value.deduplication_scope, null)
  fifo_throughput_limit       = try(each.value.fifo_throughput_limit, null)
  delay_seconds               = try(each.value.delay_seconds, 0)
  max_message_size            = try(each.value.max_message_size, 262144)
  message_retention_seconds   = try(each.value.message_retention_seconds, 345600)
  receive_wait_time_seconds   = try(each.value.receive_wait_time_seconds, 0)
  visibility_timeout_seconds  = try(each.value.visibility_timeout_seconds, 30)
  kms_key_id                  = local.sqs_kms_key_ids[each.key]
  sqs_managed_sse_enabled = (
    local.sqs_kms_key_ids[each.key] != null ? false : try(each.value.sqs_managed_sse_enabled, true)
  )
  kms_data_key_reuse_period_seconds = try(each.value.kms_data_key_reuse_period_seconds, null)
  create_dlq                  = try(each.value.create_dlq, false)
  dlq_name                    = try(each.value.dlq_name, null)
  max_receive_count           = try(each.value.max_receive_count, 3)
  redrive_policy              = try(each.value.redrive_policy, null)
  redrive_allow_policy        = try(each.value.redrive_allow_policy, null)
  policy_json                 = try(each.value.policy_json, null)
  policy_statements           = try(each.value.policy_statements, [])
  allowed_sns_topic_arns      = local.sqs_allowed_sns_topic_arns[each.key]
  tags                        = merge(var.default_tags, each.value.tags)
}

check "eks_security_group_keys" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters : alltrue([
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        contains(keys(var.security_groups), key)
      ])
    ])
    error_message = "Each EKS cluster security_group_key must exist in security_groups."
  }
}

check "eks_subnet_count" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      length(coalesce(local.eks_subnet_ids[name], [])) >= 2
    ])
    error_message = "Each EKS cluster requires at least two subnets across different Availability Zones."
  }
}

check "eks_vpc_wiring" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      length(coalesce(try(cluster.subnet_ids, null), [])) >= 2 || (
        try(cluster.vpc_key, null) != null &&
        contains(keys(var.vpcs), cluster.vpc_key) &&
        length(coalesce(try(cluster.subnet_keys, null), [])) >= 2
      )
    ])
    error_message = "Each EKS cluster requires subnet_ids (min 2) or vpc_key with subnet_keys (min 2)."
  }
}

check "eks_node_groups_required" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      length(coalesce(try(cluster.node_groups, null), {})) > 0
    ])
    error_message = "Each EKS cluster requires at least one node group."
  }
}

check "eks_kms_key_keys" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      try(cluster.kms_key_key, null) == null || contains(keys(var.kms_keys), cluster.kms_key_key)
    ])
    error_message = "Each EKS cluster kms_key_key must exist in kms_keys."
  }
}

check "eks_cluster_role_keys" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      try(cluster.cluster_role_key, null) == null || contains(keys(var.iam_roles), cluster.cluster_role_key)
    ])
    error_message = "Each EKS cluster cluster_role_key must exist in iam_roles."
  }
}

check "eks_node_role_keys" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      try(cluster.node_role_key, null) == null || contains(keys(var.iam_roles), cluster.node_role_key)
    ])
    error_message = "Each EKS cluster node_role_key must exist in iam_roles."
  }
}

check "eks_cluster_role_source_exclusive" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      (try(cluster.cluster_role_arn, null) == null) || (try(cluster.cluster_role_key, null) == null)
    ])
    error_message = "Each EKS cluster must use cluster_role_arn or cluster_role_key, not both."
  }
}

check "eks_node_role_source_exclusive" {
  assert {
    condition = length(var.eks_clusters) == 0 || alltrue([
      for name, cluster in var.eks_clusters :
      (try(cluster.node_role_arn, null) == null) || (try(cluster.node_role_key, null) == null)
    ])
    error_message = "Each EKS cluster must use node_role_arn or node_role_key, not both."
  }
}

module "eks" {
  source = "../../modules/eks"

  for_each = var.eks_clusters

  depends_on = [module.vpc, module.security_group, module.kms, module.iam_role]

  name                         = each.value.name
  kubernetes_version           = each.value.kubernetes_version
  subnet_ids                   = coalesce(local.eks_subnet_ids[each.key], [])
  security_group_ids           = coalesce(local.eks_security_group_ids[each.key], [])
  cluster_role_arn             = local.eks_cluster_role_arns[each.key]
  node_role_arn                = local.eks_node_role_arns[each.key]
  endpoint_private_access      = try(each.value.endpoint_private_access, true)
  endpoint_public_access       = try(each.value.endpoint_public_access, true)
  public_access_cidrs          = try(each.value.public_access_cidrs, ["0.0.0.0/0"])
  enabled_cluster_log_types    = try(each.value.enabled_cluster_log_types, ["api", "audit", "authenticator"])
  cloudwatch_log_retention_in_days = try(each.value.cloudwatch_log_retention_in_days, 30)
  kms_key_id                   = local.eks_kms_key_arns[each.key]
  authentication_mode          = try(each.value.authentication_mode, "API_AND_CONFIG_MAP")
  bootstrap_cluster_creator_admin_permissions = try(each.value.bootstrap_cluster_creator_admin_permissions, true)
  create_oidc_provider         = try(each.value.create_oidc_provider, true)
  node_groups                  = each.value.node_groups
  addons                       = try(each.value.addons, null)
  tags                         = merge(var.default_tags, each.value.tags)
}

check "ecr_kms_key_keys" {
  assert {
    condition = length(var.ecr_repositories) == 0 || alltrue([
      for name, repo in var.ecr_repositories :
      try(repo.kms_key_key, null) == null || contains(keys(var.kms_keys), repo.kms_key_key)
    ])
    error_message = "Each ECR repository kms_key_key must exist in kms_keys."
  }
}

check "ecr_kms_key_source_exclusive" {
  assert {
    condition = length(var.ecr_repositories) == 0 || alltrue([
      for name, repo in var.ecr_repositories :
      try(repo.kms_key_id, null) == null || try(repo.kms_key_key, null) == null
    ])
    error_message = "Each ECR repository must use kms_key_id or kms_key_key, not both."
  }
}

check "ecr_encryption_kms_key" {
  assert {
    condition = length(var.ecr_repositories) == 0 || alltrue([
      for name, repo in var.ecr_repositories :
      coalesce(try(repo.encryption_type, "AES256"), "AES256") != "KMS" || (
        try(repo.kms_key_id, null) != null || try(repo.kms_key_key, null) != null
      )
    ])
    error_message = "Each KMS-encrypted ECR repository requires kms_key_id or kms_key_key."
  }
}

check "ecr_lifecycle_policy_source_exclusive" {
  assert {
    condition = length(var.ecr_repositories) == 0 || alltrue([
      for name, repo in var.ecr_repositories :
      try(repo.lifecycle_policy_json, null) == null || length(coalesce(try(repo.lifecycle_rules, null), [])) == 0
    ])
    error_message = "Each ECR repository cannot combine lifecycle_policy_json with lifecycle_rules."
  }
}

check "ecr_policy_source_exclusive" {
  assert {
    condition = length(var.ecr_repositories) == 0 || alltrue([
      for name, repo in var.ecr_repositories :
      try(repo.policy_json, null) == null || length(coalesce(try(repo.policy_statements, null), [])) == 0
    ])
    error_message = "Each ECR repository cannot combine policy_json with policy_statements."
  }
}

module "ecr" {
  source = "../../modules/ecr"

  for_each = var.ecr_repositories

  depends_on = [module.kms]

  name                 = each.value.name
  image_tag_mutability = try(each.value.image_tag_mutability, "MUTABLE")
  force_delete         = try(each.value.force_delete, false)
  encryption_type      = try(each.value.encryption_type, "AES256")
  kms_key_id           = local.ecr_kms_key_ids[each.key]
  scan_on_push         = try(each.value.scan_on_push, true)
  policy_json          = try(each.value.policy_json, null)
  policy_statements    = try(each.value.policy_statements, [])
  lifecycle_policy_json = try(each.value.lifecycle_policy_json, null)
  lifecycle_rules      = try(each.value.lifecycle_rules, [])
  tags                 = merge(var.default_tags, each.value.tags)
}

check "ecs_subnet_reference" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters :
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 || (
        try(cluster.vpc_key, null) != null &&
        contains(keys(var.vpcs), cluster.vpc_key) &&
        length(coalesce(try(cluster.subnet_keys, null), [])) > 0
      )
    ])
    error_message = "Each ECS cluster requires subnet_ids or vpc_key with subnet_keys."
  }
}

check "ecs_security_group_reference" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters :
      length(coalesce(try(cluster.security_group_ids, null), [])) > 0 ||
      length(coalesce(try(cluster.security_group_keys, null), [])) > 0
    ])
    error_message = "Each ECS cluster requires security_group_ids or security_group_keys."
  }
}

check "ecs_execution_role_keys" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters :
      try(cluster.execution_role_key, null) == null || contains(keys(var.iam_roles), cluster.execution_role_key)
    ])
    error_message = "Each ECS cluster execution_role_key must exist in iam_roles."
  }
}

check "ecs_execution_role_source_exclusive" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters :
      try(cluster.execution_role_arn, null) == null || try(cluster.execution_role_key, null) == null
    ])
    error_message = "Each ECS cluster must use execution_role_arn or execution_role_key, not both."
  }
}

check "ecs_container_image_sources" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters : alltrue([
        for svc_name, svc in cluster.services : alltrue([
          for cname, container in svc.containers :
          try(container.image, null) != null || (
            try(container.ecr_repository_key, null) != null &&
            contains(keys(var.ecr_repositories), container.ecr_repository_key)
          )
        ])
      ])
    ])
    error_message = "Each ECS container requires image or a valid ecr_repository_key."
  }
}

check "ecs_service_task_role_keys" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters : alltrue([
        for svc_name, svc in cluster.services :
        try(svc.task_role_key, null) == null || contains(keys(var.iam_roles), svc.task_role_key)
      ])
    ])
    error_message = "Each ECS service task_role_key must exist in iam_roles."
  }
}

check "ecs_target_group_attachments" {
  assert {
    condition = length(var.ecs_clusters) == 0 || alltrue([
      for name, cluster in var.ecs_clusters : alltrue([
        for svc_name, svc in cluster.services : alltrue([
          for attachment in coalesce(try(svc.target_group_attachments, null), []) :
          contains(keys(var.load_balancers), attachment.alb_key) &&
          contains(keys(var.load_balancers[attachment.alb_key].target_groups), attachment.target_group_key)
        ])
      ])
    ])
    error_message = "Each ECS target_group_attachment must reference a valid load_balancers target group."
  }
}

module "ecs" {
  source = "../../modules/ecs"

  for_each = var.ecs_clusters

  depends_on = [module.vpc, module.security_group, module.iam_role, module.ecr, module.alb]

  name                      = each.value.name
  subnet_ids                = local.ecs_subnet_ids[each.key]
  security_group_ids        = local.ecs_security_group_ids[each.key]
  execution_role_arn        = local.ecs_execution_role_arns[each.key]
  container_insights        = try(each.value.container_insights, true)
  capacity_providers        = try(each.value.capacity_providers, ["FARGATE", "FARGATE_SPOT"])
  default_capacity_provider = try(each.value.default_capacity_provider, "FARGATE")
  services = {
    for svc_name, svc in local.ecs_services[each.key] : svc_name => {
      desired_count                      = svc.desired_count
      launch_type                        = try(svc.launch_type, "FARGATE")
      cpu                                = try(svc.cpu, 256)
      memory                             = try(svc.memory, 512)
      execution_role_arn                 = try(svc.execution_role_arn, null)
      task_role_arn                      = try(svc.task_role_arn, null)
      platform_version                   = try(svc.platform_version, "LATEST")
      assign_public_ip                   = try(svc.assign_public_ip, false)
      enable_execute_command             = try(svc.enable_execute_command, false)
      deployment_minimum_healthy_percent = try(svc.deployment_minimum_healthy_percent, 100)
      deployment_maximum_percent         = try(svc.deployment_maximum_percent, 200)
      health_check_grace_period_seconds  = try(svc.health_check_grace_period_seconds, null)
      subnet_ids                         = try(svc.subnet_ids, null)
      security_group_ids                 = try(svc.security_group_ids, null)
      log_retention_in_days              = try(svc.log_retention_in_days, 30)
      containers = {
        for cname, container in svc.containers : cname => {
          image         = container.image
          essential     = try(container.essential, true)
          cpu           = try(container.cpu, null)
          memory        = try(container.memory, null)
          command       = try(container.command, null)
          entry_point   = try(container.entry_point, null)
          environment   = try(container.environment, {})
          secrets       = try(container.secrets, [])
          port_mappings = try(container.port_mappings, [])
        }
      }
      load_balancers = try(svc.load_balancers, [])
    }
  }
  tags = merge(var.default_tags, each.value.tags)
}

check "efs_subnet_reference" {
  assert {
    condition = length(var.efs_file_systems) == 0 || alltrue([
      for name, fs in var.efs_file_systems :
      length(coalesce(try(fs.subnet_ids, null), [])) > 0 || (
        try(fs.vpc_key, null) != null &&
        contains(keys(var.vpcs), fs.vpc_key) &&
        length(coalesce(try(fs.subnet_keys, null), [])) > 0
      )
    ])
    error_message = "Each EFS file system requires subnet_ids or vpc_key with subnet_keys."
  }
}

check "efs_security_group_reference" {
  assert {
    condition = length(var.efs_file_systems) == 0 || alltrue([
      for name, fs in var.efs_file_systems :
      length(coalesce(try(fs.security_group_ids, null), [])) > 0 ||
      length(coalesce(try(fs.security_group_keys, null), [])) > 0
    ])
    error_message = "Each EFS file system requires security_group_ids or security_group_keys."
  }
}

check "efs_kms_key_keys" {
  assert {
    condition = length(var.efs_file_systems) == 0 || alltrue([
      for name, fs in var.efs_file_systems :
      try(fs.kms_key_key, null) == null || contains(keys(var.kms_keys), fs.kms_key_key)
    ])
    error_message = "Each EFS file system kms_key_key must exist in kms_keys."
  }
}

check "efs_kms_key_source_exclusive" {
  assert {
    condition = length(var.efs_file_systems) == 0 || alltrue([
      for name, fs in var.efs_file_systems :
      try(fs.kms_key_id, null) == null || try(fs.kms_key_key, null) == null
    ])
    error_message = "Each EFS file system must use kms_key_id or kms_key_key, not both."
  }
}

check "efs_provisioned_throughput" {
  assert {
    condition = length(var.efs_file_systems) == 0 || alltrue([
      for name, fs in var.efs_file_systems :
      coalesce(try(fs.throughput_mode, "bursting"), "bursting") != "provisioned" || (
        try(fs.provisioned_throughput_in_mibps, null) != null
      )
    ])
    error_message = "Each provisioned-throughput EFS file system requires provisioned_throughput_in_mibps."
  }
}

module "efs" {
  source = "../../modules/efs"

  for_each = var.efs_file_systems

  depends_on = [module.vpc, module.security_group, module.kms]

  name                            = each.value.name
  performance_mode              = try(each.value.performance_mode, "generalPurpose")
  throughput_mode                 = try(each.value.throughput_mode, "bursting")
  provisioned_throughput_in_mibps = try(each.value.provisioned_throughput_in_mibps, null)
  encrypted                       = try(each.value.encrypted, true)
  kms_key_id                      = local.efs_kms_key_ids[each.key]
  subnet_ids                      = local.efs_subnet_ids[each.key]
  security_group_ids              = local.efs_security_group_ids[each.key]
  lifecycle_policy                = try(each.value.lifecycle_policy, null)
  enable_backup_policy            = try(each.value.enable_backup_policy, false)
  backup_policy_status            = try(each.value.backup_policy_status, "ENABLED")
  access_points                   = try(each.value.access_points, {})
  tags                            = merge(var.default_tags, each.value.tags)
}

check "cognito_lambda_keys" {
  assert {
    condition = length(var.cognito_user_pools) == 0 || alltrue(flatten([
      for name, pool in var.cognito_user_pools : [
        try(pool.lambda_config.pre_sign_up_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.pre_sign_up_key),
        try(pool.lambda_config.custom_message_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.custom_message_key),
        try(pool.lambda_config.post_confirmation_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.post_confirmation_key),
        try(pool.lambda_config.pre_authentication_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.pre_authentication_key),
        try(pool.lambda_config.post_authentication_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.post_authentication_key),
        try(pool.lambda_config.define_auth_challenge_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.define_auth_challenge_key),
        try(pool.lambda_config.create_auth_challenge_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.create_auth_challenge_key),
        try(pool.lambda_config.verify_auth_challenge_response_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.verify_auth_challenge_response_key),
        try(pool.lambda_config.user_migration_key, null) == null || contains(keys(var.lambda_functions), pool.lambda_config.user_migration_key),
      ]
    ]))
    error_message = "Each Cognito lambda_config *_key must exist in lambda_functions."
  }
}

check "cognito_iam_role_keys" {
  assert {
    condition = length(var.cognito_user_pools) == 0 || alltrue([
      for name, pool in var.cognito_user_pools :
      try(pool.identity_pool, null) == null || alltrue([
        try(pool.identity_pool.authenticated_role_key, null) == null || contains(keys(var.iam_roles), pool.identity_pool.authenticated_role_key),
        try(pool.identity_pool.unauthenticated_role_key, null) == null || contains(keys(var.iam_roles), pool.identity_pool.unauthenticated_role_key),
      ])
    ])
    error_message = "Each Cognito identity_pool *_role_key must exist in iam_roles."
  }
}

check "cognito_identity_pool_client_keys" {
  assert {
    condition = length(var.cognito_user_pools) == 0 || alltrue([
      for name, pool in var.cognito_user_pools :
      try(pool.identity_pool, null) == null || contains(keys(pool.clients), pool.identity_pool.client_key)
    ])
    error_message = "Each Cognito identity_pool.client_key must exist in clients."
  }
}

check "cognito_domain_source_exclusive" {
  assert {
    condition = length(var.cognito_user_pools) == 0 || alltrue([
      for name, pool in var.cognito_user_pools :
      try(pool.domain, null) == null || (
        (try(pool.domain.prefix, null) != null) != (try(pool.domain.custom_domain, null) != null)
      )
    ])
    error_message = "Each Cognito domain must set exactly one of prefix or custom_domain."
  }
}

check "cognito_clients_required" {
  assert {
    condition = length(var.cognito_user_pools) == 0 || alltrue([
      for name, pool in var.cognito_user_pools :
      length(pool.clients) > 0
    ])
    error_message = "Each Cognito user pool requires at least one client."
  }
}

module "cognito" {
  source = "../../modules/cognito"

  for_each = var.cognito_user_pools

  depends_on = [module.lambda, module.iam_role]

  name                     = each.value.name
  username_attributes      = try(each.value.username_attributes, ["email"])
  auto_verified_attributes = try(each.value.auto_verified_attributes, ["email"])
  deletion_protection      = try(each.value.deletion_protection, "INACTIVE")
  mfa_configuration        = try(each.value.mfa_configuration, "OFF")
  password_policy          = try(each.value.password_policy, {})
  account_recovery_mechanisms = try(each.value.account_recovery_mechanisms, [{ name = "verified_email", priority = 1 }])
  advanced_security_mode   = try(each.value.advanced_security_mode, "OFF")
  email_configuration      = try(each.value.email_configuration, null)
  lambda_config            = local.cognito_lambda_configs[each.key]
  domain                   = try(each.value.domain, null)
  clients                  = each.value.clients
  identity_pool            = local.cognito_identity_pools[each.key]
  tags                     = merge(var.default_tags, each.value.tags)
}

check "msk_subnet_reference" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 || (
        try(cluster.vpc_key, null) != null &&
        contains(keys(var.vpcs), cluster.vpc_key) &&
        length(coalesce(try(cluster.subnet_keys, null), [])) > 0
      )
    ])
    error_message = "Each MSK cluster requires subnet_ids or vpc_key with subnet_keys."
  }
}

check "msk_security_group_reference" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      length(coalesce(try(cluster.security_group_ids, null), [])) > 0 ||
      length(coalesce(try(cluster.security_group_keys, null), [])) > 0
    ])
    error_message = "Each MSK cluster requires security_group_ids or security_group_keys."
  }
}

check "msk_security_group_keys" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      alltrue([
        for key in coalesce(try(cluster.security_group_keys, null), []) :
        contains(keys(var.security_groups), key)
      ])
    ])
    error_message = "Each MSK cluster security_group_keys entry must exist in security_groups."
  }
}

check "msk_subnet_keys_valid" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      length(coalesce(try(cluster.subnet_ids, null), [])) > 0 || alltrue([
        for key in coalesce(try(cluster.subnet_keys, null), []) :
        try(cluster.vpc_key, null) != null &&
        contains(keys(var.vpcs), cluster.vpc_key) &&
        contains(keys(var.vpcs[cluster.vpc_key].private_subnets), key)
      ])
    ])
    error_message = "Each MSK cluster subnet_keys entry must exist in the referenced vpc private_subnets."
  }
}

check "msk_effective_subnet_count" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      local.msk_effective_subnet_counts[name] >= 2
    ])
    error_message = "Each MSK cluster must resolve to at least two subnets across availability zones."
  }
}

check "msk_kms_key_keys" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      try(cluster.kms_key_key, null) == null || contains(keys(var.kms_keys), cluster.kms_key_key)
    ])
    error_message = "Each MSK cluster kms_key_key must exist in kms_keys."
  }
}

check "msk_kms_key_source_exclusive" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      try(cluster.kms_key_id, null) == null || try(cluster.kms_key_key, null) == null
    ])
    error_message = "Each MSK cluster must use kms_key_id or kms_key_key, not both."
  }
}

check "msk_scram_secret_keys" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      alltrue([
        for key in coalesce(try(cluster.scram_secret_keys, null), []) :
        contains(keys(var.secrets), key)
      ])
    ])
    error_message = "Each MSK cluster scram_secret_keys entry must exist in secrets."
  }
}

check "msk_logging_bucket_keys" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      try(cluster.logging.s3.bucket_key, null) == null || contains(keys(var.buckets), cluster.logging.s3.bucket_key)
    ])
    error_message = "Each MSK cluster logging.s3.bucket_key must exist in buckets."
  }
}

check "msk_broker_nodes_multiple_of_subnets" {
  assert {
    condition = length(var.msk_clusters) == 0 || alltrue([
      for name, cluster in var.msk_clusters :
      local.msk_effective_subnet_counts[name] > 0 &&
      try(cluster.number_of_broker_nodes, 3) % local.msk_effective_subnet_counts[name] == 0
    ])
    error_message = "Each MSK cluster number_of_broker_nodes must be a multiple of its resolved subnet count."
  }
}

module "msk" {
  source = "../../modules/msk"

  for_each = var.msk_clusters

  depends_on = [module.vpc, module.security_group, module.kms, module.secrets_manager, module.s3]

  name                   = each.value.name
  kafka_version          = try(each.value.kafka_version, "3.6.0")
  number_of_broker_nodes = try(each.value.number_of_broker_nodes, 3)
  broker_instance_type     = try(each.value.broker_instance_type, "kafka.m5.large")
  subnet_ids             = local.msk_subnet_ids[each.key]
  security_group_ids     = local.msk_security_group_ids[each.key]
  ebs_volume_size        = try(each.value.ebs_volume_size, 100)
  ebs_provisioned_throughput = try(each.value.ebs_provisioned_throughput, null)
  kms_key_id             = local.msk_kms_key_ids[each.key]
  encryption_in_transit  = try(each.value.encryption_in_transit, {})
  client_authentication  = try(each.value.client_authentication, {})
  public_access          = try(each.value.public_access, "DISABLED")
  configuration          = try(each.value.configuration, null)
  logging                = local.msk_logging[each.key]
  open_monitoring        = try(each.value.open_monitoring, null)
  enhanced_monitoring    = try(each.value.enhanced_monitoring, "DEFAULT")
  storage_mode           = try(each.value.storage_mode, "LOCAL")
  scram_secret_arns      = local.msk_scram_secret_arns[each.key]
  tags                   = merge(var.default_tags, each.value.tags)
}
