variable "aws_region" {
  description = "AWS region where resources are created."
  type        = string
  default     = "us-east-1"
}

variable "aws_replica_region" {
  description = "AWS region used by the aws.replica provider for KMS replica keys."
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Default tags applied to all resources via the AWS provider."
  type        = map(string)
  default     = {}
}

variable "buckets" {
  description = "S3 buckets to create in this environment. Omit from tfvars when not managing S3."
  type = map(object({
    bucket_name             = string
    force_destroy           = optional(bool, false)
    versioning_enabled      = optional(bool, false)
    sse_algorithm           = optional(string, "AES256")
    kms_key_arn             = optional(string, null)
    bucket_key_enabled      = optional(bool, true)
    object_ownership        = optional(string, "BucketOwnerEnforced")
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
    access_logging = optional(object({
      target_bucket = string
      target_prefix = optional(string, "")
    }))
    lifecycle_rules = optional(list(object({
      id      = string
      enabled = optional(bool, true)
      filter = optional(object({
        prefix                   = optional(string)
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        tags                     = optional(map(string), {})
      }))
      expiration = optional(object({
        days                         = optional(number)
        expired_object_delete_marker = optional(bool)
      }))
      transitions = optional(list(object({
        days          = number
        storage_class = string
      })), [])
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
      }))
    })), [])
    bucket_policy_json = optional(string, null)
    cors_rules = optional(list(object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "secrets" {
  description = "Secrets Manager secrets to create in this environment. Omit from tfvars when not managing secrets."
  type = map(object({
    name                    = optional(string)
    name_prefix             = optional(string)
    description             = optional(string, null)
    kms_key_id              = optional(string, null)
    recovery_window_in_days = optional(number, 30)
    secret_string           = optional(string, null)
    secret_binary           = optional(string, null)
    generate_random_password = optional(object({
      length           = optional(number, 32)
      special          = optional(bool, true)
      override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
      username         = optional(string, null)
    }))
    ignore_secret_changes = optional(bool, false)
    rotation = optional(object({
      lambda_arn               = string
      automatically_after_days = optional(number, 30)
    }))
    resource_policy_json = optional(string, null)
    replica_regions = optional(list(object({
      region     = string
      kms_key_id = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "kms_keys" {
  description = "KMS keys to create in this environment. Omit from tfvars when not managing KMS."
  type = map(object({
    description             = optional(string, null)
    deletion_window_in_days = optional(number, 30)
    enable_key_rotation     = optional(bool, true)
    multi_region            = optional(bool, false)
    replica_region          = optional(string, null)
    key_policy_json         = optional(string, null)
    allowed_services        = optional(list(string), [])
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), ["*"])
      principals = object({
        type        = string
        identifiers = list(string)
      })
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    aliases = optional(list(string), [])
    tags    = optional(map(string), {})
  }))
  default = {}
}

variable "lambda_functions" {
  description = "Lambda functions to create in this environment. Omit from tfvars when not managing Lambda."
  type = map(object({
    function_name = string
    role_name     = optional(string)
    description   = optional(string, null)
    package_type  = optional(string, "Zip")
    runtime       = optional(string, null)
    handler       = optional(string, null)
    filename      = optional(string, null)
    s3_bucket     = optional(string, null)
    s3_key        = optional(string, null)
    s3_object_version = optional(string, null)
    package_source_dir = optional(string, null)
    source_code_hash  = optional(string, null)
    image_uri     = optional(string, null)
    memory_size   = optional(number, 128)
    timeout       = optional(number, 3)
    architectures = optional(list(string), ["x86_64"])
    environment_variables = optional(map(string), {})
    kms_key_arn   = optional(string, null)
    layers        = optional(list(string), [])
    ephemeral_storage_size = optional(number, 512)
    reserved_concurrent_executions = optional(number, null)
    tracing_mode  = optional(string, "PassThrough")
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    dead_letter_config = optional(object({
      target_arn = string
    }))
    create_log_group      = optional(bool, true)
    log_retention_in_days = optional(number, 14)
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), ["*"])
    })), [])
    function_url = optional(object({
      authorization_type = optional(string, "AWS_IAM")
      cors = optional(object({
        allow_credentials = optional(bool, false)
        allow_headers     = optional(list(string), [])
        allow_methods     = optional(list(string), [])
        allow_origins     = optional(list(string), [])
        expose_headers    = optional(list(string), [])
        max_age           = optional(number)
      }))
    }))
    event_source_mappings = optional(list(object({
      name                               = string
      event_source_arn                   = string
      batch_size                         = optional(number, 10)
      enabled                            = optional(bool, true)
      maximum_batching_window_in_seconds = optional(number)
      function_response_types            = optional(list(string), [])
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cloudfront_distributions" {
  description = "CloudFront distributions with S3 origins to create in this environment. Omit from tfvars when not managing CloudFront."
  type = map(object({
    distribution_comment             = optional(string)
    enabled                          = optional(bool, true)
    price_class                      = optional(string, "PriceClass_100")
    origin_id                        = optional(string)
    default_root_object              = optional(string, "index.html")
    spa_fallback                     = optional(bool, false)
    wait_for_deployment              = optional(bool, true)
    cache_policy_id                  = optional(string, "658327ea-f89d-4fab-a63d-7e88639e58f6")
    origin_request_policy_id         = optional(string)
    response_headers_policy_id       = optional(string)
    create_origin_bucket             = optional(bool, true)
    origin_bucket_name               = optional(string)
    origin_bucket_force_destroy      = optional(bool, false)
    origin_bucket_versioning_enabled = optional(bool, false)
    origin_sse_algorithm             = optional(string, "AES256")
    origin_kms_key_arn               = optional(string)
    origin_bucket_key_enabled        = optional(bool, true)
    existing_origin_bucket_id                   = optional(string)
    existing_origin_bucket_arn                  = optional(string)
    existing_origin_bucket_regional_domain_name = optional(string)
    manage_origin_bucket_policy                 = optional(bool)
    origin_path                      = optional(string, "")
    viewer_protocol_policy           = optional(string, "redirect-to-https")
    allowed_methods                  = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods                   = optional(list(string), ["GET", "HEAD"])
    compress                         = optional(bool, true)
    min_ttl                          = optional(number, 0)
    default_ttl                      = optional(number, 3600)
    max_ttl                          = optional(number, 86400)
    forward_query_string             = optional(bool, false)
    forward_cookies                  = optional(string, "none")
    forwarded_cookie_names           = optional(list(string), [])
    forward_headers                  = optional(list(string), [])
    ordered_cache_behaviors = optional(list(object({
      path_pattern           = string
      allowed_methods        = list(string)
      cached_methods         = list(string)
      target_origin_id       = optional(string)
      viewer_protocol_policy = optional(string, "redirect-to-https")
      compress               = optional(bool, true)
      min_ttl                = optional(number, 0)
      default_ttl            = optional(number, 3600)
      max_ttl                = optional(number, 86400)
      forward_query_string   = optional(bool, false)
      forward_cookies        = optional(string, "none")
      forwarded_cookie_names = optional(list(string), [])
      forward_headers        = optional(list(string), [])
      cache_policy_id            = optional(string)
      origin_request_policy_id   = optional(string)
      response_headers_policy_id = optional(string)
    })), [])
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
    origin_bucket_policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string))
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    custom_error_responses = optional(list(object({
      error_code            = number
      response_code         = optional(number)
      response_page_path    = optional(string)
      error_caching_min_ttl = optional(number)
    })), [])
    aliases                   = optional(list(string), [])
    acm_certificate_arn       = optional(string)
    minimum_protocol_version  = optional(string, "TLSv1.2_2021")
    ssl_support_method        = optional(string, "sni-only")
    geo_restriction_type      = optional(string, "none")
    geo_restriction_locations = optional(list(string), [])
    logging_config = optional(object({
      bucket          = string
      prefix          = optional(string, "")
      include_cookies = optional(bool, false)
    }))
    web_acl_id      = optional(string)
    http_version    = optional(string, "http2")
    is_ipv6_enabled = optional(bool, true)
    tags            = optional(map(string), {})
  }))
  default = {}
}

variable "vpcs" {
  description = "VPCs to create in this environment. Omit from tfvars when not managing VPC."
  type = map(object({
    name                   = string
    cidr_block             = string
    enable_dns_hostnames   = optional(bool, true)
    enable_dns_support     = optional(bool, true)
    enable_nat_gateway     = optional(bool, true)
    single_nat_gateway     = optional(bool, true)
    one_nat_gateway_per_az = optional(bool, false)
    create_public_nacl     = optional(bool, true)
    create_private_nacl    = optional(bool, true)
    public_subnets = map(object({
      availability_zone       = string
      cidr_block              = string
      map_public_ip_on_launch = optional(bool, true)
    }))
    private_subnets = map(object({
      availability_zone = string
      cidr_block        = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "load_balancers" {
  description = "Application Load Balancers to create in this environment. Omit from tfvars when not managing ALB."
  type = map(object({
    name                       = string
    vpc_id                     = optional(string)
    vpc_key                    = optional(string)
    subnet_ids                 = optional(list(string))
    internal                   = optional(bool, false)
    ip_address_type            = optional(string, "ipv4")
    create_security_group      = optional(bool, true)
    security_group_ids         = optional(list(string), [])
    allowed_ingress_cidrs      = optional(list(string), ["0.0.0.0/0"])
    enable_deletion_protection = optional(bool, false)
    idle_timeout               = optional(number, 60)
    drop_invalid_header_fields = optional(bool, true)
    enable_http2               = optional(bool, true)
    access_logs = optional(object({
      bucket  = string
      prefix  = optional(string, "")
      enabled = optional(bool, true)
    }))
    target_groups = map(object({
      port                             = number
      protocol                         = string
      target_type                      = string
      vpc_id                           = optional(string)
      load_balancing_algorithm_type    = optional(string, "round_robin")
      deregistration_delay             = optional(number, 300)
      slow_start                       = optional(number, 0)
      health_check_enabled             = optional(bool, true)
      health_check_interval            = optional(number, 30)
      health_check_path                = optional(string, "/")
      health_check_port                = optional(string, "traffic-port")
      health_check_protocol            = optional(string, "HTTP")
      health_check_timeout             = optional(number, 5)
      health_check_healthy_threshold   = optional(number, 3)
      health_check_unhealthy_threshold = optional(number, 3)
      health_check_matcher             = optional(string, "200-399")
      stickiness_enabled               = optional(bool, false)
      stickiness_type                  = optional(string, "lb_cookie")
      stickiness_cookie_duration       = optional(number, 86400)
      targets = optional(list(object({
        id                = string
        port              = optional(number)
        availability_zone = optional(string)
      })), [])
    }))
    listeners = map(object({
      port            = number
      protocol        = string
      certificate_arn = optional(string)
      ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
      default_action = object({
        type             = string
        target_group_key = optional(string)
        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = string
        }))
        redirect = optional(object({
          port        = string
          protocol    = string
          status_code = string
          host        = optional(string)
          path        = optional(string)
          query       = optional(string)
        }))
      })
      rules = optional(list(object({
        name         = string
        priority     = number
        host_header  = optional(list(string))
        path_pattern = optional(list(string))
        http_header = optional(object({
          name   = string
          values = list(string)
        }))
        action = object({
          type             = string
          target_group_key = optional(string)
          fixed_response = optional(object({
            content_type = string
            message_body = string
            status_code  = string
          }))
          redirect = optional(object({
            port        = string
            protocol    = string
            status_code = string
            host        = optional(string)
            path        = optional(string)
            query       = optional(string)
          }))
        })
      })), [])
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "security_groups" {
  description = "Security groups to create in this environment. Omit from tfvars when not managing security groups."
  type = map(object({
    name                   = string
    vpc_key                = optional(string)
    vpc_id                 = optional(string)
    description            = optional(string)
    revoke_rules_on_delete = optional(bool, true)
    ingress_rules = optional(list(object({
      description                  = optional(string)
      protocol                     = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_blocks                  = optional(list(string), [])
      ipv6_cidr_blocks             = optional(list(string), [])
      prefix_list_ids              = optional(list(string), [])
      referenced_security_group_id = optional(string)
      self_reference               = optional(bool, false)
    })), [])
    egress_rules = optional(list(object({
      description                  = optional(string)
      protocol                     = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_blocks                  = optional(list(string), [])
      ipv6_cidr_blocks             = optional(list(string), [])
      prefix_list_ids              = optional(list(string), [])
      referenced_security_group_id = optional(string)
      self_reference               = optional(bool, false)
    })))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "network_load_balancers" {
  description = "Network Load Balancers to create in this environment. Omit from tfvars when not managing NLB."
  type = map(object({
    name                             = string
    vpc_id                           = optional(string)
    vpc_key                          = optional(string)
    subnet_ids                       = optional(list(string))
    internal                         = optional(bool, false)
    ip_address_type                  = optional(string, "ipv4")
    security_group_ids               = optional(list(string), [])
    enable_deletion_protection       = optional(bool, false)
    enable_cross_zone_load_balancing = optional(bool, true)
    access_logs = optional(object({
      bucket  = string
      prefix  = optional(string, "")
      enabled = optional(bool, true)
    }))
    subnet_mappings = optional(list(object({
      subnet_id            = string
      allocation_id        = optional(string)
      private_ipv4_address = optional(string)
      ipv6_address         = optional(string)
    })), [])
    target_groups = map(object({
      port                             = number
      protocol                         = string
      target_type                      = string
      vpc_id                           = optional(string)
      deregistration_delay             = optional(number, 300)
      preserve_client_ip               = optional(bool)
      connection_termination           = optional(bool)
      proxy_protocol_v2                = optional(bool, false)
      health_check_enabled             = optional(bool, true)
      health_check_interval            = optional(number, 30)
      health_check_port                = optional(string, "traffic-port")
      health_check_protocol            = optional(string, "TCP")
      health_check_path                = optional(string)
      health_check_timeout             = optional(number, 10)
      health_check_healthy_threshold   = optional(number, 3)
      health_check_unhealthy_threshold = optional(number, 3)
      health_check_matcher             = optional(string)
      stickiness_enabled               = optional(bool, false)
      stickiness_type                  = optional(string, "source_ip")
      targets = optional(list(object({
        id                = string
        port              = optional(number)
        availability_zone = optional(string)
      })), [])
    }))
    listeners = map(object({
      port             = number
      protocol         = string
      certificate_arn  = optional(string)
      ssl_policy       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
      alpn_policy      = optional(string)
      target_group_key = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "codebuild_projects" {
  description = "CodeBuild projects to create in this environment. Omit from tfvars when not managing CodeBuild."
  type = map(object({
    name                   = string
    description            = optional(string)
    build_timeout          = optional(number, 60)
    queued_timeout         = optional(number, 480)
    concurrent_build_limit = optional(number)
    badge_enabled          = optional(bool, false)
    encryption_key         = optional(string)
    create_service_role    = optional(bool, true)
    service_role_arn       = optional(string)
    role_name              = optional(string)
    managed_policy_arns    = optional(list(string), [])
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), ["*"])
    })), [])
    create_log_group      = optional(bool, true)
    log_retention_in_days = optional(number, 30)
    buildspec             = optional(string)
    source_version        = optional(string)
    vpc_id                = optional(string)
    vpc_key               = optional(string)
    subnet_ids            = optional(list(string))
    security_group_ids    = optional(list(string))
    security_group_key    = optional(string)
    vpc_config = optional(object({
      vpc_id             = string
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    source = object({
      type                = string
      location            = optional(string)
      buildspec           = optional(string)
      git_clone_depth     = optional(number, 1)
      insecure_ssl        = optional(bool, false)
      report_build_status = optional(bool, false)
      fetch_submodules    = optional(bool, false)
      auth = optional(object({
        type     = string
        resource = optional(string)
      }))
    })
    artifacts = optional(object({
      type                   = string
      location               = optional(string)
      path                   = optional(string)
      namespace_type         = optional(string)
      packaging              = optional(string)
      encryption_disabled    = optional(bool, false)
      override_artifact_name = optional(bool, false)
      artifact_identifier    = optional(string)
      name                   = optional(string)
    }), {
      type = "NO_ARTIFACTS"
    })
    cache = optional(object({
      type     = string
      location = optional(string)
      modes    = optional(list(string), [])
    }))
    environment = object({
      compute_type                = optional(string, "BUILD_GENERAL1_SMALL")
      image                       = string
      type                        = optional(string, "LINUX_CONTAINER")
      privileged_mode             = optional(bool, false)
      image_pull_credentials_type = optional(string, "CODEBUILD")
      certificate                 = optional(string)
      registry_credential = optional(object({
        credential          = string
        credential_provider = string
      }))
      environment_variables = optional(list(object({
        name  = string
        value = string
        type  = optional(string, "PLAINTEXT")
      })), [])
    })
    logs_config = optional(object({
      cloudwatch_logs = optional(object({
        group_name  = optional(string)
        stream_name = optional(string)
        status      = optional(string, "ENABLED")
      }))
      s3_logs = optional(object({
        status              = optional(string, "DISABLED")
        location            = optional(string)
        encryption_disabled = optional(bool, false)
        bucket_owner_access = optional(string)
      }))
    }), {
      cloudwatch_logs = {
        status = "ENABLED"
      }
    })
    webhook = optional(object({
      build_type = optional(string, "BUILD")
      filter_groups = optional(list(list(object({
        type                    = string
        pattern                 = string
        exclude_matched_pattern = optional(bool)
      }))), [])
    }))
    file_system_locations = optional(list(object({
      identifier  = string
      location    = string
      mount_point = string
      type        = optional(string, "EFS")
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "codepipelines" {
  description = "CodePipelines to create in this environment. Omit from tfvars when not managing CodePipeline."
  type = map(object({
    name                  = string
    pipeline_type         = optional(string, "V2")
    execution_mode        = optional(string, "SUPERSEDED")
    artifact_bucket       = optional(string)
    artifact_bucket_key   = optional(string)
    artifact_kms_key_arn  = optional(string)
    artifact_kms_key_key  = optional(string)
    artifact_store_region = optional(string)
    secondary_artifact_stores = optional(list(object({
      location    = string
      region      = string
      kms_key_arn = optional(string)
    })), [])
    create_service_role = optional(bool, true)
    service_role_arn    = optional(string)
    role_name           = optional(string)
    managed_policy_arns = optional(list(string), [])
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), ["*"])
    })), [])
    stages = list(object({
      name = string
      actions = list(object({
        name                  = string
        category              = string
        owner                 = string
        provider              = string
        version               = string
        input_artifacts       = optional(list(string), [])
        output_artifacts      = optional(list(string), [])
        role_arn              = optional(string)
        run_order             = optional(number)
        namespace             = optional(string)
        codebuild_project_key = optional(string)
        configuration         = optional(map(string), {})
      }))
    }))
    trigger = optional(object({
      provider_type = string
      git_configuration = object({
        source_action_name = string
        push = optional(list(object({
          branches = optional(object({
            includes = optional(list(string), [])
            excludes = optional(list(string), [])
          }))
          tags = optional(object({
            includes = optional(list(string), [])
            excludes = optional(list(string), [])
          }))
        })), [])
      })
    }))
    variables = optional(list(object({
      name          = string
      default_value = string
      description   = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "iam_roles" {
  description = "IAM roles to create in this environment. Omit from tfvars when not managing standalone IAM roles."
  type = map(object({
    name                  = string
    description           = optional(string)
    path                  = optional(string, "/")
    max_session_duration  = optional(number, 3600)
    permissions_boundary  = optional(string)
    force_detach_policies = optional(bool, false)
    assume_role_policy_json = optional(string)
    trust_services        = optional(list(string), [])
    trust_principals = optional(list(object({
      type        = string
      identifiers = list(string)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    assume_role_actions = optional(list(string), ["sts:AssumeRole"])
    assume_role_conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
    managed_policy_arns = optional(list(string), [])
    managed_policy_keys = optional(list(string), [])
    policy_statements = optional(list(object({
      sid           = optional(string)
      effect        = string
      actions       = optional(list(string), [])
      not_actions   = optional(list(string), [])
      resources     = optional(list(string), ["*"])
      not_resources = optional(list(string), [])
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    inline_policies = optional(map(object({
      policy_statements = list(object({
        sid           = optional(string)
        effect        = string
        actions       = optional(list(string), [])
        not_actions   = optional(list(string), [])
        resources     = optional(list(string), ["*"])
        not_resources = optional(list(string), [])
        conditions = optional(list(object({
          test     = string
          variable = string
          values   = list(string)
        })), [])
      }))
    })), {})
    create_instance_profile = optional(bool, false)
    instance_profile_name   = optional(string)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "iam_policies" {
  description = "IAM customer-managed policies to create in this environment. Omit from tfvars when not managing standalone IAM policies."
  type = map(object({
    name        = optional(string)
    name_prefix = optional(string)
    description = optional(string)
    path        = optional(string, "/")
    policy_json = optional(string)
    policy_statements = optional(list(object({
      sid           = optional(string)
      effect        = string
      actions       = optional(list(string), [])
      not_actions   = optional(list(string), [])
      resources     = optional(list(string), ["*"])
      not_resources = optional(list(string), [])
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "iam_users" {
  description = "IAM users to create in this environment. Omit from tfvars when not managing standalone IAM users."
  type = map(object({
    name                  = string
    path                  = optional(string, "/")
    permissions_boundary  = optional(string)
    permissions_boundary_key = optional(string)
    force_destroy         = optional(bool, false)
    managed_policy_arns   = optional(list(string), [])
    managed_policy_keys   = optional(list(string), [])
    policy_statements = optional(list(object({
      sid           = optional(string)
      effect        = string
      actions       = optional(list(string), [])
      not_actions   = optional(list(string), [])
      resources     = optional(list(string), ["*"])
      not_resources = optional(list(string), [])
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    inline_policies = optional(map(object({
      policy_statements = list(object({
        sid           = optional(string)
        effect        = string
        actions       = optional(list(string), [])
        not_actions   = optional(list(string), [])
        resources     = optional(list(string), ["*"])
        not_resources = optional(list(string), [])
        conditions = optional(list(object({
          test     = string
          variable = string
          values   = list(string)
        })), [])
      }))
    })), {})
    create_access_key = optional(bool, false)
    access_key_status = optional(string, "Active")
    access_key_pgp_key = optional(string)
    create_login_profile = optional(bool, false)
    login_profile_password_reset_required = optional(bool, true)
    login_profile_password_length         = optional(number, 20)
    login_profile_pgp_key                 = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "ec2_instances" {
  description = "EC2 instances to create in this environment. Omit from tfvars when not managing EC2 instances."
  type = map(object({
    name          = string
    instance_type = string
    ami           = optional(string)
    ami_lookup = optional(object({
      owners      = optional(list(string), ["amazon"])
      most_recent = optional(bool, true)
      filters     = map(list(string))
    }))
    vpc_key     = optional(string)
    subnet_key  = optional(string)
    subnet_type = optional(string, "private")
    subnet_id   = optional(string)
    security_group_ids  = optional(list(string), [])
    security_group_keys = optional(list(string), [])
    key_name = optional(string) # Omit for keyless instances (use SSM Session Manager)
    iam_instance_profile  = optional(string)
    iam_role_key          = optional(string)
    availability_zone     = optional(string)
    associate_public_ip_address = optional(bool)
    private_ip              = optional(string)
    secondary_private_ips   = optional(list(string), [])
    source_dest_check       = optional(bool)
    user_data               = optional(string)
    user_data_base64        = optional(string)
    user_data_replace_on_change = optional(bool, false)
    monitoring              = optional(bool, false)
    ebs_optimized           = optional(bool)
    disable_api_termination = optional(bool, false)
    instance_initiated_shutdown_behavior = optional(string)
    tenancy                 = optional(string, "default")
    placement_group         = optional(string)
    hibernation             = optional(bool, false)
    root_block_device = optional(object({
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string)
      kms_key_key           = optional(string)
      delete_on_termination = optional(bool, true)
    }))
    ebs_block_devices = optional(map(object({
      device_name           = string
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string)
      kms_key_key           = optional(string)
      delete_on_termination = optional(bool, true)
      snapshot_id           = optional(string)
    })), {})
    metadata_options = optional(object({
      http_endpoint               = optional(string, "enabled")
      http_tokens                 = optional(string, "required")
      http_put_response_hop_limit = optional(number, 1)
      instance_metadata_tags      = optional(string, "disabled")
    }))
    cpu_options = optional(object({
      core_count       = number
      threads_per_core = number
    }))
    credit_specification = optional(object({
      cpu_credits = string
    }))
    create_eip           = optional(bool, false)
    eip_domain           = optional(string, "vpc")
    ignore_ami_changes   = optional(bool, false)
    volume_tags          = optional(map(string), {})
    tags                 = optional(map(string), {})
  }))
  default = {}
}

variable "rds_instances" {
  description = "RDS instances to create in this environment. Omit from tfvars when not managing RDS."
  type = map(object({
    identifier        = string
    engine            = string
    engine_version    = optional(string)
    engine_version_lookup = optional(object({
      version = string
      latest  = optional(bool, true)
    }))
    instance_class    = string
    allocated_storage = number
    username          = string
    password          = optional(string)
    manage_master_user_password = optional(bool, false)
    generate_password = optional(object({
      length           = optional(number, 32)
      special          = optional(bool, true)
      override_special = optional(string, "!#$%&*()-_=+[]{}<>:?")
    }))
    max_allocated_storage = optional(number, 0)
    storage_type          = optional(string, "gp3")
    iops                  = optional(number)
    storage_throughput    = optional(number)
    db_name               = optional(string)
    port                  = optional(number)
    vpc_key               = optional(string)
    subnet_keys           = optional(list(string), [])
    subnet_ids            = optional(list(string), [])
    db_subnet_group_name  = optional(string)
    create_db_subnet_group = optional(bool, true)
    security_group_ids    = optional(list(string), [])
    security_group_keys   = optional(list(string), [])
    parameter_group_name  = optional(string)
    create_parameter_group = optional(bool, false)
    parameter_group_family = optional(string)
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    multi_az            = optional(bool, false)
    publicly_accessible = optional(bool, false)
    storage_encrypted   = optional(bool, true)
    kms_key_id          = optional(string)
    kms_key_key         = optional(string)
    backup_retention_period = optional(number, 7)
    backup_window           = optional(string)
    maintenance_window    = optional(string)
    deletion_protection   = optional(bool, true)
    skip_final_snapshot   = optional(bool, false)
    final_snapshot_identifier = optional(string)
    apply_immediately     = optional(bool, false)
    auto_minor_version_upgrade = optional(bool, true)
    monitoring_interval = optional(number, 0)
    monitoring_role_arn   = optional(string)
    enabled_cloudwatch_logs_exports = optional(list(string), [])
    performance_insights_enabled = optional(bool, false)
    performance_insights_kms_key_id = optional(string)
    performance_insights_retention_period = optional(number)
    copy_tags_to_snapshot = optional(bool, true)
    iam_database_authentication_enabled = optional(bool, false)
    ca_cert_identifier    = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "api_gateways" {
  description = "API Gateway HTTP/WebSocket APIs to create in this environment. Omit from tfvars when not managing API Gateway."
  type = map(object({
    name          = string
    description   = optional(string)
    protocol_type = optional(string, "HTTP")
    disable_execute_api_endpoint = optional(bool, false)
    cors_configuration = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string), [])
      allow_methods     = optional(list(string), [])
      allow_origins     = optional(list(string), [])
      expose_headers    = optional(list(string), [])
      max_age           = optional(number)
    }))
    integrations = map(object({
      integration_type       = string
      integration_method     = optional(string, "POST")
      integration_uri        = optional(string)
      lambda_function_key    = optional(string)
      load_balancer_key      = optional(string)
      connection_type        = optional(string, "INTERNET")
      connection_id          = optional(string)
      payload_format_version = optional(string, "2.0")
      timeout_milliseconds   = optional(number, 30000)
      credentials_arn        = optional(string)
      request_parameters     = optional(map(string), {})
      tls_config = optional(object({
        server_name_to_verify = optional(string)
      }))
    }))
    routes = map(object({
      route_key                  = string
      integration_key            = string
      authorization_type         = optional(string, "NONE")
      authorizer_key             = optional(string)
      authorization_scopes       = optional(list(string), [])
      api_key_required           = optional(bool, false)
      operation_name             = optional(string)
      model_selection_expression = optional(string)
    }))
    authorizers = optional(map(object({
      authorizer_type  = string
      identity_sources = optional(list(string), [])
      name             = optional(string)
      jwt_configuration = optional(object({
        audience = list(string)
        issuer   = string
      }))
      authorizer_uri        = optional(string)
      lambda_function_key   = optional(string)
      authorizer_payload_format_version = optional(string, "2.0")
      authorizer_result_ttl_in_seconds = optional(number, 300)
      enable_simple_responses          = optional(bool, false)
    })), {})
    stages = map(object({
      name        = string
      auto_deploy = optional(bool, true)
      description = optional(string)
      access_log_settings = optional(object({
        destination_arn = string
        format          = string
      }))
      default_route_settings = optional(object({
        detailed_metrics_enabled = optional(bool, false)
        throttling_burst_limit   = optional(number)
        throttling_rate_limit    = optional(number)
      }))
      route_settings = optional(map(object({
        detailed_metrics_enabled = optional(bool, false)
        throttling_burst_limit   = optional(number)
        throttling_rate_limit    = optional(number)
      })), {})
      variables   = optional(map(string), {})
      web_acl_arn = optional(string)
    }))
    api_keys = optional(map(object({
      name        = optional(string)
      description = optional(string)
    })), {})
    domain = optional(object({
      domain_name     = string
      certificate_arn = string
      security_policy = optional(string, "TLS_1_2")
      stage_key       = string
      mapping_key     = optional(string)
    }))
    vpc_link = optional(object({
      name                = string
      vpc_key             = optional(string)
      subnet_keys         = optional(list(string), [])
      subnet_ids          = optional(list(string), [])
      security_group_keys = optional(list(string), [])
      security_group_ids  = optional(list(string), [])
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "sns_topics" {
  description = "SNS topics to create in this environment. Omit from tfvars when not managing SNS."
  type = map(object({
    name                        = optional(string)
    name_prefix                 = optional(string)
    display_name                = optional(string)
    fifo_topic                  = optional(bool, false)
    content_based_deduplication = optional(bool, false)
    fifo_throughput_scope       = optional(string)
    kms_key_id                  = optional(string)
    kms_key_key                 = optional(string)
    delivery_policy             = optional(string)
    archive_policy              = optional(string)
    policy_json = optional(string)
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), [])
      principals = object({
        type        = string
        identifiers = list(string)
      })
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    subscriptions = optional(map(object({
      protocol                        = string
      endpoint                        = optional(string)
      lambda_function_key             = optional(string)
      endpoint_auto_confirms          = optional(bool, false)
      confirmation_timeout_in_minutes = optional(number)
      raw_message_delivery            = optional(bool, false)
      filter_policy                   = optional(string)
      filter_policy_scope             = optional(string)
      redrive_policy                  = optional(string)
      subscription_role_arn           = optional(string)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "sqs_queues" {
  description = "SQS queues to create in this environment. Omit from tfvars when not managing SQS."
  type = map(object({
    name                        = optional(string)
    name_prefix                 = optional(string)
    fifo_queue                  = optional(bool, false)
    content_based_deduplication = optional(bool, false)
    deduplication_scope         = optional(string)
    fifo_throughput_limit       = optional(string)
    delay_seconds               = optional(number, 0)
    max_message_size            = optional(number, 262144)
    message_retention_seconds   = optional(number, 345600)
    receive_wait_time_seconds   = optional(number, 0)
    visibility_timeout_seconds  = optional(number, 30)
    kms_key_id                  = optional(string)
    kms_key_key                 = optional(string)
    sqs_managed_sse_enabled     = optional(bool, true)
    kms_data_key_reuse_period_seconds = optional(number)
    create_dlq                  = optional(bool, false)
    dlq_name                    = optional(string)
    max_receive_count           = optional(number, 3)
    redrive_policy              = optional(string)
    redrive_allow_policy        = optional(string)
    policy_json                 = optional(string)
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), [])
      principals = object({
        type        = string
        identifiers = list(string)
      })
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    sns_topic_keys = optional(list(string), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "eks_clusters" {
  description = "EKS clusters to create in this environment. Omit from tfvars when not managing EKS."
  type = map(object({
    name               = string
    kubernetes_version = string
    vpc_key            = optional(string)
    subnet_keys        = optional(list(string), [])
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    security_group_keys = optional(list(string), [])
    cluster_role_arn  = optional(string)
    cluster_role_key  = optional(string)
    node_role_arn     = optional(string)
    node_role_key     = optional(string)
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, true)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    enabled_cluster_log_types = optional(list(string), ["api", "audit", "authenticator"])
    cloudwatch_log_retention_in_days = optional(number, 30)
    kms_key_id         = optional(string)
    kms_key_key        = optional(string)
    authentication_mode = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    create_oidc_provider = optional(bool, true)
    node_groups = map(object({
      instance_types = list(string)
      capacity_type  = optional(string, "ON_DEMAND")
      ami_type       = optional(string)
      disk_size      = optional(number, 20)
      desired_size   = number
      min_size       = number
      max_size       = number
      subnet_ids     = optional(list(string))
      labels         = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = optional(string)
        effect = string
      })), [])
      max_unavailable            = optional(number)
      max_unavailable_percentage = optional(number)
      release_version            = optional(string)
    }))
    addons = optional(map(object({
      addon_version               = optional(string)
      resolve_conflicts_on_create = optional(string, "OVERWRITE")
      resolve_conflicts_on_update = optional(string, "OVERWRITE")
      service_account_role_arn    = optional(string)
      configuration_values        = optional(string)
    })))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "ecr_repositories" {
  description = "ECR repositories to create in this environment. Omit from tfvars when not managing ECR."
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    force_delete         = optional(bool, false)
    encryption_type      = optional(string, "AES256")
    kms_key_id           = optional(string)
    kms_key_key          = optional(string)
    scan_on_push         = optional(bool, true)
    policy_json          = optional(string)
    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = optional(list(string), [])
      principals = object({
        type        = string
        identifiers = list(string)
      })
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    lifecycle_policy_json = optional(string)
    lifecycle_rules = optional(list(object({
      rule_priority   = number
      description     = optional(string)
      tag_status      = optional(string, "any")
      tag_prefix_list = optional(list(string), [])
      count_type      = string
      count_unit      = optional(string)
      count_number    = number
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "ecs_clusters" {
  description = "ECS clusters to create in this environment. Omit from tfvars when not managing ECS."
  type = map(object({
    name       = string
    vpc_key    = optional(string)
    subnet_ids = optional(list(string), [])
    subnet_keys = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    security_group_keys = optional(list(string), [])
    execution_role_arn  = optional(string)
    execution_role_key  = optional(string)
    container_insights  = optional(bool, true)
    capacity_providers  = optional(list(string), ["FARGATE", "FARGATE_SPOT"])
    default_capacity_provider = optional(string, "FARGATE")
    services = map(object({
      desired_count = number
      launch_type   = optional(string, "FARGATE")
      cpu           = optional(number, 256)
      memory        = optional(number, 512)
      execution_role_arn = optional(string)
      execution_role_key = optional(string)
      task_role_arn      = optional(string)
      task_role_key      = optional(string)
      platform_version   = optional(string, "LATEST")
      assign_public_ip   = optional(bool, false)
      enable_execute_command = optional(bool, false)
      deployment_minimum_healthy_percent = optional(number, 100)
      deployment_maximum_percent         = optional(number, 200)
      health_check_grace_period_seconds  = optional(number)
      subnet_ids         = optional(list(string))
      security_group_ids = optional(list(string))
      log_retention_in_days = optional(number, 30)
      containers = map(object({
        image               = optional(string)
        image_tag           = optional(string, "latest")
        ecr_repository_key  = optional(string)
        essential           = optional(bool, true)
        cpu                 = optional(number)
        memory              = optional(number)
        command             = optional(list(string))
        entry_point         = optional(list(string))
        environment         = optional(map(string), {})
        secrets = optional(list(object({
          name       = string
          value_from = string
        })), [])
        port_mappings = optional(list(object({
          container_port = number
          host_port      = optional(number)
          protocol       = optional(string, "tcp")
        })), [])
      }))
      load_balancers = optional(list(object({
        target_group_arn = string
        container_name   = string
        container_port   = number
      })), [])
      target_group_attachments = optional(list(object({
        alb_key          = string
        target_group_key = string
        container_name   = string
        container_port   = number
      })), [])
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "efs_file_systems" {
  description = "EFS file systems to create in this environment. Omit from tfvars when not managing EFS."
  type = map(object({
    name       = string
    vpc_key    = optional(string)
    subnet_ids = optional(list(string), [])
    subnet_keys = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    security_group_keys = optional(list(string), [])
    performance_mode = optional(string, "generalPurpose")
    throughput_mode  = optional(string, "bursting")
    provisioned_throughput_in_mibps = optional(number)
    encrypted  = optional(bool, true)
    kms_key_id = optional(string)
    kms_key_key = optional(string)
    lifecycle_policy = optional(object({
      transition_to_ia                    = optional(string)
      transition_to_archive               = optional(string)
      transition_to_primary_storage_class = optional(string)
    }))
    enable_backup_policy  = optional(bool, false)
    backup_policy_status  = optional(string, "ENABLED")
    access_points = optional(map(object({
      path = string
      posix_user = optional(object({
        uid = number
        gid = number
      }))
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }))
      tags = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cognito_user_pools" {
  description = "Cognito user pools to create in this environment. Omit from tfvars when not managing Cognito."
  type = map(object({
    name                     = string
    username_attributes      = optional(list(string), ["email"])
    auto_verified_attributes = optional(list(string), ["email"])
    deletion_protection      = optional(string, "INACTIVE")
    mfa_configuration        = optional(string, "OFF")
    password_policy = optional(object({
      minimum_length                   = optional(number, 12)
      require_lowercase                = optional(bool, true)
      require_numbers                  = optional(bool, true)
      require_symbols                  = optional(bool, true)
      require_uppercase                = optional(bool, true)
      temporary_password_validity_days = optional(number, 7)
    }), {})
    account_recovery_mechanisms = optional(list(object({
      name     = string
      priority = number
    })), [{ name = "verified_email", priority = 1 }])
    advanced_security_mode = optional(string, "OFF")
    email_configuration = optional(object({
      email_sending_account  = optional(string, "COGNITO_DEFAULT")
      source_arn             = optional(string)
      from_email_address     = optional(string)
      reply_to_email_address = optional(string)
    }))
    lambda_config = optional(object({
      pre_sign_up_arn                    = optional(string)
      pre_sign_up_key                    = optional(string)
      custom_message_arn                 = optional(string)
      custom_message_key                 = optional(string)
      post_confirmation_arn            = optional(string)
      post_confirmation_key            = optional(string)
      pre_authentication_arn           = optional(string)
      pre_authentication_key           = optional(string)
      post_authentication_arn          = optional(string)
      post_authentication_key          = optional(string)
      define_auth_challenge_arn          = optional(string)
      define_auth_challenge_key          = optional(string)
      create_auth_challenge_arn          = optional(string)
      create_auth_challenge_key          = optional(string)
      verify_auth_challenge_response_arn = optional(string)
      verify_auth_challenge_response_key = optional(string)
      user_migration_arn                 = optional(string)
      user_migration_key                 = optional(string)
    }), {})
    domain = optional(object({
      prefix          = optional(string)
      custom_domain   = optional(string)
      certificate_arn = optional(string)
    }))
    clients = map(object({
      name                                 = optional(string)
      generate_secret                      = optional(bool, false)
      explicit_auth_flows                  = optional(list(string), ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
      allowed_oauth_flows                  = optional(list(string), [])
      allowed_oauth_flows_user_pool_client = optional(bool, false)
      allowed_oauth_scopes                 = optional(list(string), [])
      callback_urls                        = optional(list(string), [])
      logout_urls                          = optional(list(string), [])
      default_redirect_uri                 = optional(string)
      supported_identity_providers         = optional(list(string), ["COGNITO"])
      prevent_user_existence_errors        = optional(string, "ENABLED")
      access_token_validity                = optional(number, 60)
      id_token_validity                    = optional(number, 60)
      refresh_token_validity               = optional(number, 30)
      access_token_unit                    = optional(string, "minutes")
      id_token_unit                        = optional(string, "minutes")
      refresh_token_unit                   = optional(string, "days")
    }))
    identity_pool = optional(object({
      name                           = string
      client_key                     = string
      allow_unauthenticated_identities = optional(bool, false)
      authenticated_role_arn         = optional(string)
      authenticated_role_key         = optional(string)
      unauthenticated_role_arn       = optional(string)
      unauthenticated_role_key       = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "msk_clusters" {
  description = "MSK Kafka clusters to create in this environment. Omit from tfvars when not managing MSK."
  type = map(object({
    name                     = string
    kafka_version            = optional(string, "3.6.0")
    number_of_broker_nodes   = optional(number, 3)
    broker_instance_type     = optional(string, "kafka.m5.large")
    vpc_key                  = optional(string)
    subnet_ids               = optional(list(string), [])
    subnet_keys              = optional(list(string), [])
    security_group_ids       = optional(list(string), [])
    security_group_keys      = optional(list(string), [])
    ebs_volume_size          = optional(number, 100)
    ebs_provisioned_throughput = optional(object({
      enabled           = optional(bool, false)
      volume_throughput = optional(number)
    }))
    kms_key_id  = optional(string)
    kms_key_key = optional(string)
    encryption_in_transit = optional(object({
      client_broker = optional(string, "TLS")
      in_cluster    = optional(bool, true)
    }), {})
    client_authentication = optional(object({
      unauthenticated = optional(bool, false)
      sasl = optional(object({
        scram = optional(bool, false)
        iam   = optional(bool, false)
      }))
      tls = optional(object({
        certificate_authority_arns = optional(list(string), [])
      }))
    }), {})
    public_access = optional(string, "DISABLED")
    configuration = optional(object({
      create            = optional(bool, false)
      name              = optional(string)
      server_properties = optional(map(string), {})
      arn               = optional(string)
      revision          = optional(number)
    }))
    logging = optional(object({
      cloudwatch = optional(object({
        enabled           = optional(bool, true)
        log_group_name    = optional(string)
        retention_in_days = optional(number, 30)
      }))
      s3 = optional(object({
        enabled    = optional(bool, false)
        bucket     = optional(string)
        bucket_key = optional(string)
        prefix     = optional(string, "")
      }))
      firehose = optional(object({
        enabled         = optional(bool, false)
        delivery_stream = optional(string)
      }))
    }))
    open_monitoring = optional(object({
      jmx_exporter_enabled  = optional(bool, false)
      node_exporter_enabled = optional(bool, false)
    }))
    enhanced_monitoring = optional(string, "DEFAULT")
    storage_mode        = optional(string, "LOCAL")
    scram_secret_arns   = optional(list(string), [])
    scram_secret_keys   = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
  default = {}
}
