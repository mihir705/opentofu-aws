# CloudFront Module

OpenTofu module to create a CloudFront distribution with an S3 origin using Origin Access Control (OAC). Optionally creates a private origin bucket with secure defaults and attaches the required bucket policy.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_cloudfront_origin_access_control` | Yes | SigV4 signing for S3 origin |
| `aws_cloudfront_distribution` | Yes | CDN distribution |
| `aws_s3_bucket` | No | Created when `create_origin_bucket = true` |
| `aws_s3_bucket_public_access_block` | No | Blocks all public access on created bucket |
| `aws_s3_bucket_ownership_controls` | No | `BucketOwnerEnforced` on created bucket |
| `aws_s3_bucket_versioning` | No | On created bucket |
| `aws_s3_bucket_server_side_encryption_configuration` | No | SSE-S3 or SSE-KMS on created bucket |
| `aws_s3_bucket_policy` | No | OAC policy when `manage_origin_bucket_policy = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples to use in `environments/prod/terraform.tfvars`.

### Static site with managed origin bucket

```hcl
module "static_site" {
  source = "./modules/cloudfront"

  distribution_comment = "Company marketing site"
  origin_bucket_name = "my-company-static-site-prod"
  default_root_object  = "index.html"

  custom_error_responses = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  tags = {
    Environment = "prod"
    Purpose     = "static-site"
  }
}
```

After `tofu apply`, upload site files to the origin bucket:

```bash
aws s3 sync ./dist s3://my-company-static-site-prod/
```

Access the site at `https://<distribution_domain_name>` from module outputs.

### Custom domain with ACM

ACM certificates for CloudFront must be created in **us-east-1**.

```hcl
module "static_site" {
  source = "./modules/cloudfront"

  origin_bucket_name = "my-company-static-site-prod"
  aliases            = ["www.example.com"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-5678-90ab-cdef-1234567890ab"

  tags = {
    Environment = "prod"
  }
}
```

### Existing S3 origin bucket

Use when the origin bucket is managed separately (for example by the S3 module). Do not set `bucket_policy_json` on the S3 bucket if this module will manage the OAC policy.

```hcl
module "static_site" {
  source = "./modules/cloudfront"

  create_origin_bucket = false
  manage_origin_bucket_policy = true

  existing_origin_bucket_id                   = module.app_data.bucket_id
  existing_origin_bucket_arn                  = module.app_data.bucket_arn
  existing_origin_bucket_regional_domain_name = module.app_data.bucket_regional_domain_name

  distribution_comment = "CDN for existing bucket"

  tags = {
    Environment = "prod"
  }
}
```

If the existing bucket already has a bucket policy, set `manage_origin_bucket_policy = false` and merge the OAC statement from the module output `origin_access_control_id` into your policy manually.

### Environment stack (prod)

```hcl
cloudfront_distributions = {
  static-site = {
    origin_bucket_name  = "my-company-static-site-prod"
    default_root_object = "index.html"

    tags = {
      Purpose = "static-site"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `distribution_comment` | Comment for the distribution | `string` | `null` | no |
| `enabled` | Enable the distribution | `bool` | `true` | no |
| `price_class` | CloudFront price class | `string` | `"PriceClass_100"` | no |
| `default_root_object` | Root object (e.g. `index.html`) | `string` | `"index.html"` | no |
| `create_origin_bucket` | Create a private S3 origin bucket | `bool` | `true` | no |
| `origin_bucket_name` | Origin bucket name when creating | `string` | `null` | yes* |
| `origin_bucket_force_destroy` | Allow bucket delete with objects | `bool` | `false` | no |
| `origin_bucket_versioning_enabled` | Versioning on created bucket | `bool` | `false` | no |
| `origin_sse_algorithm` | `AES256` or `aws:kms` | `string` | `"AES256"` | no |
| `origin_kms_key_arn` | KMS key when using SSE-KMS | `string` | `null` | no |
| `existing_origin_bucket_id` | Existing bucket ID | `string` | `null` | yes** |
| `existing_origin_bucket_arn` | Existing bucket ARN | `string` | `null` | yes** |
| `existing_origin_bucket_regional_domain_name` | Existing bucket regional domain | `string` | `null` | yes** |
| `manage_origin_bucket_policy` | Attach OAC bucket policy | `bool` | `create_origin_bucket` | no |
| `origin_path` | Origin path prefix | `string` | `""` | no |
| `viewer_protocol_policy` | `allow-all`, `https-only`, `redirect-to-https` | `string` | `"redirect-to-https"` | no |
| `allowed_methods` | Allowed HTTP methods | `list(string)` | `["GET", "HEAD", "OPTIONS"]` | no |
| `cached_methods` | Cached HTTP methods | `list(string)` | `["GET", "HEAD"]` | no |
| `compress` | Enable compression | `bool` | `true` | no |
| `min_ttl` | Minimum TTL (seconds) | `number` | `0` | no |
| `default_ttl` | Default TTL (seconds) | `number` | `3600` | no |
| `max_ttl` | Maximum TTL (seconds) | `number` | `86400` | no |
| `forward_query_string` | Forward query strings | `bool` | `false` | no |
| `forward_cookies` | `none`, `whitelist`, or `all` | `string` | `"none"` | no |
| `forwarded_cookie_names` | Cookie names when whitelisting | `list(string)` | `[]` | no |
| `forward_headers` | Headers forwarded to origin | `list(string)` | `[]` | no |
| `ordered_cache_behaviors` | Additional path-based behaviors | `list(object)` | `[]` | no |
| `custom_error_responses` | Custom error responses | `list(object)` | `[]` | no |
| `aliases` | Alternate domain names | `list(string)` | `[]` | no |
| `acm_certificate_arn` | ACM cert ARN (us-east-1) | `string` | `null` | yes*** |
| `minimum_protocol_version` | Minimum TLS version | `string` | `"TLSv1.2_2021"` | no |
| `ssl_support_method` | `sni-only` or `vip` | `string` | `"sni-only"` | no |
| `geo_restriction_type` | `none`, `whitelist`, `blacklist` | `string` | `"none"` | no |
| `geo_restriction_locations` | ISO country codes | `list(string)` | `[]` | no |
| `logging_config` | Standard access logging | `object` | `null` | no |
| `web_acl_id` | WAF web ACL ARN or ID | `string` | `null` | no |
| `http_version` | `http1.1`, `http2`, `http2and3`, `http3` | `string` | `"http2"` | no |
| `is_ipv6_enabled` | Enable IPv6 | `bool` | `true` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

\* Required when `create_origin_bucket = true`.

\** Required when `create_origin_bucket = false`.

\*** Required when `aliases` is non-empty.

## Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | CloudFront distribution ID |
| `distribution_arn` | CloudFront distribution ARN |
| `distribution_domain_name` | `*.cloudfront.net` domain name |
| `distribution_hosted_zone_id` | Route 53 alias target hosted zone ID |
| `distribution_status` | Deployment status |
| `origin_access_control_id` | OAC ID for the S3 origin |
| `origin_bucket_id` | S3 origin bucket ID |
| `origin_bucket_arn` | S3 origin bucket ARN |
| `origin_bucket_regional_domain_name` | S3 origin regional domain name |
| `origin_bucket_created` | Whether the module created the bucket |
| `origin_bucket_policy_managed` | Whether the module attached the OAC policy |

## Design notes

- **OAC over OAI**: Uses Origin Access Control (SigV4), the current AWS recommendation for private S3 origins.
- **Private origin**: The created S3 bucket blocks all public access. Only CloudFront can read objects via the bucket policy.
- **Bucket policy ordering**: The OAC bucket policy references the distribution ARN and is applied after the distribution is created.
- **Managed cache policies**: Defaults to AWS `CachingOptimized` (`658327ea-f89d-4fab-a63d-7e88639e58f6`). Set `cache_policy_id = null` to use legacy TTL and forwarding controls.
- **SPA routing with OAC**: Private S3 origins return **403** (not 404) for missing keys. Use `spa_fallback = true` to map both 403 and 404 to `default_root_object`.
- **Origin ID**: Derived from the bucket name by default — not from `distribution_comment` — to keep technical identifiers stable.
- **Existing bucket validation**: When `create_origin_bucket = false`, Terraform verifies ARN and domain name match the referenced bucket.
- **Extensible bucket policy**: `origin_bucket_policy_statements` merges additional IAM statements into the OAC policy.

## Common workflow

1. `tofu apply` to create distribution and origin bucket.
2. Upload static assets to the origin bucket (`aws s3 sync` or CI/CD).
3. Optionally create a Route 53 alias record to `distribution_domain_name` using `distribution_hosted_zone_id`.
4. For custom domains, request an ACM certificate in `us-east-1`, add `aliases`, and point DNS to CloudFront.
