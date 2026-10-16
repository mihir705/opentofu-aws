output "environment" {
  description = "Outputs for resources managed in this environment. Only includes resource types configured in terraform.tfvars."
  value = merge(
    length(var.buckets) > 0 ? {
      s3 = {
        ids                   = { for name, bucket in module.s3 : name => bucket.bucket_id }
        arns                  = { for name, bucket in module.s3 : name => bucket.bucket_arn }
        domain_names          = { for name, bucket in module.s3 : name => bucket.bucket_domain_name }
        regional_domain_names = { for name, bucket in module.s3 : name => bucket.bucket_regional_domain_name }
      }
    } : {},
    length(var.secrets) > 0 ? {
      secrets = {
        arns  = { for name, secret in module.secrets_manager : name => secret.secret_arn }
        names = { for name, secret in module.secrets_manager : name => secret.secret_name }
        ids   = { for name, secret in module.secrets_manager : name => secret.secret_id }
      }
    } : {},
    length(var.kms_keys) > 0 ? {
      kms = {
        ids            = { for name, key in module.kms : name => key.key_id }
        arns           = { for name, key in module.kms : name => key.key_arn }
        alias_arns     = { for name, key in module.kms : name => key.alias_arns }
        replica_key_arns = { for name, key in module.kms : name => key.replica_key_arn }
      }
    } : {},
    length(var.lambda_functions) > 0 ? {
      lambda = {
        names        = { for name, fn in module.lambda : name => fn.function_name }
        arns         = { for name, fn in module.lambda : name => fn.function_arn }
        invoke_arns  = { for name, fn in module.lambda : name => fn.invoke_arn }
        role_arns    = { for name, fn in module.lambda : name => fn.role_arn }
        function_urls = { for name, fn in module.lambda : name => fn.function_url }
      }
    } : {},
    length(var.cloudfront_distributions) > 0 ? {
      cloudfront = {
        distribution_ids   = { for name, dist in module.cloudfront : name => dist.distribution_id }
        distribution_arns  = { for name, dist in module.cloudfront : name => dist.distribution_arn }
        domain_names       = { for name, dist in module.cloudfront : name => dist.distribution_domain_name }
        hosted_zone_ids    = { for name, dist in module.cloudfront : name => dist.distribution_hosted_zone_id }
        origin_bucket_ids  = { for name, dist in module.cloudfront : name => dist.origin_bucket_id }
        origin_bucket_arns = { for name, dist in module.cloudfront : name => dist.origin_bucket_arn }
      }
    } : {},
    length(var.vpcs) > 0 ? {
      vpc = {
        ids                  = { for name, vpc in module.vpc : name => vpc.vpc_id }
        arns                 = { for name, vpc in module.vpc : name => vpc.vpc_arn }
        cidr_blocks          = { for name, vpc in module.vpc : name => vpc.vpc_cidr_block }
        public_subnet_ids    = { for name, vpc in module.vpc : name => vpc.public_subnet_ids }
        private_subnet_ids   = { for name, vpc in module.vpc : name => vpc.private_subnet_ids }
        nat_gateway_ids      = { for name, vpc in module.vpc : name => vpc.nat_gateway_ids }
        internet_gateway_ids = { for name, vpc in module.vpc : name => vpc.internet_gateway_id }
      }
    } : {},
    length(var.load_balancers) > 0 ? {
      alb = {
        arns         = { for name, alb in module.alb : name => alb.load_balancer_arn }
        dns_names    = { for name, alb in module.alb : name => alb.load_balancer_dns_name }
        zone_ids     = { for name, alb in module.alb : name => alb.load_balancer_zone_id }
        target_group_arns = { for name, alb in module.alb : name => alb.target_group_arns }
        security_group_ids = { for name, alb in module.alb : name => alb.security_group_id }
        listener_arns = { for name, alb in module.alb : name => alb.listener_arns }
      }
    } : {},
    length(var.security_groups) > 0 ? {
      security_groups = {
        ids   = { for name, sg in module.security_group : name => sg.security_group_id }
        arns  = { for name, sg in module.security_group : name => sg.security_group_arn }
        names = { for name, sg in module.security_group : name => sg.security_group_name }
      }
    } : {},
    length(var.network_load_balancers) > 0 ? {
      nlb = {
        arns              = { for name, nlb in module.nlb : name => nlb.load_balancer_arn }
        dns_names         = { for name, nlb in module.nlb : name => nlb.load_balancer_dns_name }
        zone_ids          = { for name, nlb in module.nlb : name => nlb.load_balancer_zone_id }
        target_group_arns = { for name, nlb in module.nlb : name => nlb.target_group_arns }
        listener_arns     = { for name, nlb in module.nlb : name => nlb.listener_arns }
      }
    } : {},
    length(var.codebuild_projects) > 0 ? {
      codebuild = {
        names            = { for name, project in module.codebuild : name => project.project_name }
        arns             = { for name, project in module.codebuild : name => project.project_arn }
        service_role_arns = { for name, project in module.codebuild : name => project.service_role_arn }
        log_group_names  = { for name, project in module.codebuild : name => project.log_group_name }
        badge_urls       = { for name, project in module.codebuild : name => project.badge_url }
        webhook_urls     = { for name, project in module.codebuild : name => project.webhook_url }
      }
    } : {},
    length(var.codepipelines) > 0 ? {
      codepipeline = {
        names             = { for name, pipeline in module.codepipeline : name => pipeline.pipeline_name }
        arns              = { for name, pipeline in module.codepipeline : name => pipeline.pipeline_arn }
        service_role_arns = { for name, pipeline in module.codepipeline : name => pipeline.service_role_arn }
        artifact_buckets  = { for name, pipeline in module.codepipeline : name => pipeline.artifact_bucket }
      }
    } : {},
    length(var.iam_policies) > 0 ? {
      iam_policies = {
        names = { for name, policy in module.iam_policy : name => policy.policy_name }
        arns  = { for name, policy in module.iam_policy : name => policy.policy_arn }
        ids   = { for name, policy in module.iam_policy : name => policy.policy_id }
      }
    } : {},
    length(var.iam_roles) > 0 ? {
      iam_roles = {
        names                 = { for name, role in module.iam_role : name => role.role_name }
        arns                  = { for name, role in module.iam_role : name => role.role_arn }
        unique_ids            = { for name, role in module.iam_role : name => role.role_unique_id }
        instance_profile_arns = { for name, role in module.iam_role : name => role.instance_profile_arn }
        instance_profile_names = { for name, role in module.iam_role : name => role.instance_profile_name }
      }
    } : {},
    length(var.iam_users) > 0 ? {
      iam_users = {
        names         = { for name, user in module.iam_user : name => user.user_name }
        arns          = { for name, user in module.iam_user : name => user.user_arn }
        unique_ids    = { for name, user in module.iam_user : name => user.user_unique_id }
        access_key_ids = { for name, user in module.iam_user : name => user.access_key_id }
      }
    } : {},
    length(var.ec2_instances) > 0 ? {
      ec2 = {
        instance_ids   = { for name, instance in module.ec2 : name => instance.instance_id }
        instance_arns  = { for name, instance in module.ec2 : name => instance.instance_arn }
        private_ips    = { for name, instance in module.ec2 : name => instance.private_ip }
        public_ips     = { for name, instance in module.ec2 : name => instance.public_ip }
        availability_zones = { for name, instance in module.ec2 : name => instance.availability_zone }
        eip_public_ips = { for name, instance in module.ec2 : name => instance.eip_public_ip }
      }
    } : {},
    length(var.rds_instances) > 0 ? {
      rds = {
        identifiers = { for name, db in module.rds : name => db.db_instance_id }
        arns        = { for name, db in module.rds : name => db.db_instance_arn }
        endpoints   = { for name, db in module.rds : name => db.db_instance_endpoint }
        addresses   = { for name, db in module.rds : name => db.db_instance_address }
        ports       = { for name, db in module.rds : name => db.db_instance_port }
        master_user_secret_arns = { for name, db in module.rds : name => db.master_user_secret_arn }
      }
    } : {},
    length(var.api_gateways) > 0 ? {
      api_gateway = {
        api_ids          = { for name, api in module.apigateway : name => api.api_id }
        api_arns         = { for name, api in module.apigateway : name => api.api_arn }
        api_endpoints    = { for name, api in module.apigateway : name => api.api_endpoint }
        execution_arns   = { for name, api in module.apigateway : name => api.execution_arn }
        stage_invoke_urls = { for name, api in module.apigateway : name => api.stage_invoke_urls }
        domain_names     = { for name, api in module.apigateway : name => api.domain_name }
      }
    } : {},
    length(var.sns_topics) > 0 ? {
      sns = {
        topic_arns          = { for name, topic in module.sns : name => topic.topic_arn }
        topic_names         = { for name, topic in module.sns : name => topic.topic_name }
        subscription_arns   = { for name, topic in module.sns : name => topic.subscription_arns }
      }
    } : {},
    length(var.sqs_queues) > 0 ? {
      sqs = {
        queue_arns  = { for name, queue in module.sqs : name => queue.queue_arn }
        queue_urls  = { for name, queue in module.sqs : name => queue.queue_url }
        queue_names = { for name, queue in module.sqs : name => queue.queue_name }
        dlq_arns    = { for name, queue in module.sqs : name => queue.dlq_arn }
      }
    } : {},
    length(var.eks_clusters) > 0 ? {
      eks = {
        cluster_names   = { for name, cluster in module.eks : name => cluster.cluster_name }
        cluster_arns    = { for name, cluster in module.eks : name => cluster.cluster_arn }
        cluster_endpoints = { for name, cluster in module.eks : name => cluster.cluster_endpoint }
        oidc_provider_arns = { for name, cluster in module.eks : name => cluster.oidc_provider_arn }
        node_group_arns = { for name, cluster in module.eks : name => cluster.node_group_arns }
      }
    } : {},
    length(var.ecr_repositories) > 0 ? {
      ecr = {
        repository_names = { for name, repo in module.ecr : name => repo.repository_name }
        repository_arns  = { for name, repo in module.ecr : name => repo.repository_arn }
        repository_urls  = { for name, repo in module.ecr : name => repo.repository_url }
        registry_ids     = { for name, repo in module.ecr : name => repo.registry_id }
      }
    } : {},
    length(var.ecs_clusters) > 0 ? {
      ecs = {
        cluster_names          = { for name, cluster in module.ecs : name => cluster.cluster_name }
        cluster_arns           = { for name, cluster in module.ecs : name => cluster.cluster_arn }
        execution_role_arns  = { for name, cluster in module.ecs : name => cluster.execution_role_arn }
        service_names          = { for name, cluster in module.ecs : name => cluster.service_names }
        task_definition_arns = { for name, cluster in module.ecs : name => cluster.task_definition_arns }
        log_group_names        = { for name, cluster in module.ecs : name => cluster.log_group_names }
      }
    } : {},
    length(var.efs_file_systems) > 0 ? {
      efs = {
        file_system_ids  = { for name, fs in module.efs : name => fs.file_system_id }
        file_system_arns = { for name, fs in module.efs : name => fs.file_system_arn }
        dns_names        = { for name, fs in module.efs : name => fs.dns_name }
        mount_target_ids = { for name, fs in module.efs : name => fs.mount_target_ids }
        access_point_arns = { for name, fs in module.efs : name => fs.access_point_arns }
      }
    } : {},
    length(var.cognito_user_pools) > 0 ? {
      cognito = {
        user_pool_ids       = { for name, pool in module.cognito : name => pool.user_pool_id }
        user_pool_arns      = { for name, pool in module.cognito : name => pool.user_pool_arn }
        user_pool_endpoints = { for name, pool in module.cognito : name => pool.user_pool_endpoint }
        client_ids          = { for name, pool in module.cognito : name => pool.client_ids }
        hosted_ui_base_urls = { for name, pool in module.cognito : name => pool.hosted_ui_base_url }
        identity_pool_ids   = { for name, pool in module.cognito : name => pool.identity_pool_id }
        identity_pool_arns  = { for name, pool in module.cognito : name => pool.identity_pool_arn }
      }
    } : {},
    length(var.msk_clusters) > 0 ? {
      msk = {
        cluster_arns                 = { for name, cluster in module.msk : name => cluster.cluster_arn }
        cluster_names                = { for name, cluster in module.msk : name => cluster.cluster_name }
        bootstrap_brokers_tls        = { for name, cluster in module.msk : name => cluster.bootstrap_brokers_tls }
        bootstrap_brokers_sasl_iam   = { for name, cluster in module.msk : name => cluster.bootstrap_brokers_sasl_iam }
        bootstrap_brokers_sasl_scram = { for name, cluster in module.msk : name => cluster.bootstrap_brokers_sasl_scram }
        zookeeper_connect_string_tls = { for name, cluster in module.msk : name => cluster.zookeeper_connect_string_tls }
        cloudwatch_log_group_names   = { for name, cluster in module.msk : name => cluster.cloudwatch_log_group_name }
      }
    } : {},
  )
}
