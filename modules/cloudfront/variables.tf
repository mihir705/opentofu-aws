variable "distribution_comment" {
  description = "Comment for the CloudFront distribution."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the distribution is enabled."
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "origin_id" {
  description = "Unique origin ID within the distribution. Defaults to a sanitized origin bucket identifier."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Default object served for the distribution root URL. Set to null to disable."
  type        = string
  default     = "index.html"
}

variable "spa_fallback" {
  description = "Map S3 OAC 403/404 responses to default_root_object for single-page apps."
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Wait until the distribution is deployed before completing apply."
  type        = bool
  default     = true
}

variable "cache_policy_id" {
  description = "Managed cache policy ID. Set to null to use legacy forwarded_values TTL and forwarding settings."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "origin_request_policy_id" {
  description = "Managed origin request policy ID. Only used when cache_policy_id is set."
  type        = string
  default     = null
}

variable "response_headers_policy_id" {
  description = "Managed response headers policy ID for security or CORS headers."
  type        = string
  default     = null
}

variable "origin_bucket_policy_statements" {
  description = "Additional IAM policy statements merged into the CloudFront OAC bucket policy."
  type = list(object({
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
  }))
  default = []
}

variable "create_origin_bucket" {
  description = "Create a dedicated private S3 origin bucket. Set to false to use an existing bucket."
  type        = bool
  default     = true
}

variable "origin_bucket_name" {
  description = "S3 bucket name for the origin. Required when create_origin_bucket is true."
  type        = string
  default     = null
}

variable "origin_bucket_force_destroy" {
  description = "Allow origin bucket deletion when it contains objects."
  type        = bool
  default     = false
}

variable "origin_bucket_versioning_enabled" {
  description = "Enable versioning on the origin bucket when it is created by this module."
  type        = bool
  default     = false
}

variable "origin_sse_algorithm" {
  description = "Server-side encryption algorithm for the origin bucket when created by this module."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.origin_sse_algorithm)
    error_message = "origin_sse_algorithm must be either AES256 or aws:kms."
  }
}

variable "origin_kms_key_arn" {
  description = "KMS key ARN when origin_sse_algorithm is aws:kms."
  type        = string
  default     = null

  validation {
    condition     = var.origin_sse_algorithm != "aws:kms" || (var.origin_kms_key_arn != null && var.origin_kms_key_arn != "")
    error_message = "origin_kms_key_arn is required when origin_sse_algorithm is aws:kms."
  }
}

variable "origin_bucket_key_enabled" {
  description = "Enable S3 Bucket Keys when origin_sse_algorithm is aws:kms."
  type        = bool
  default     = true
}

variable "existing_origin_bucket_id" {
  description = "Existing origin bucket ID or name. Required when create_origin_bucket is false."
  type        = string
  default     = null
}

variable "existing_origin_bucket_arn" {
  description = "Existing origin bucket ARN. Required when create_origin_bucket is false."
  type        = string
  default     = null
}

variable "existing_origin_bucket_regional_domain_name" {
  description = "Existing origin bucket regional domain name. Required when create_origin_bucket is false."
  type        = string
  default     = null
}

variable "manage_origin_bucket_policy" {
  description = "Attach the CloudFront OAC bucket policy to the origin bucket. Defaults to true when create_origin_bucket is true."
  type        = bool
  default     = null
}

variable "origin_path" {
  description = "Optional path prefix in the origin bucket."
  type        = string
  default     = ""
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the default cache behavior."
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "allowed_methods" {
  description = "Allowed HTTP methods for the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "Cached HTTP methods for the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "compress" {
  description = "Enable automatic compression for the default cache behavior."
  type        = bool
  default     = true
}

variable "min_ttl" {
  description = "Minimum TTL in seconds for the default cache behavior."
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL in seconds for the default cache behavior."
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL in seconds for the default cache behavior."
  type        = number
  default     = 86400
}

variable "forward_query_string" {
  description = "Forward query strings to the origin for the default cache behavior."
  type        = bool
  default     = false
}

variable "forward_cookies" {
  description = "Cookie forwarding behavior for the default cache behavior."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "all"], var.forward_cookies)
    error_message = "forward_cookies must be none, whitelist, or all."
  }
}

variable "forwarded_cookie_names" {
  description = "Cookie names to forward when forward_cookies is whitelist."
  type        = list(string)
  default     = []
}

variable "forward_headers" {
  description = "Headers forwarded to the origin for the default cache behavior."
  type        = list(string)
  default     = []
}

variable "ordered_cache_behaviors" {
  description = "Additional cache behaviors ordered by path pattern."
  type = list(object({
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
  }))
  default = []
}

variable "function_associations" {
  description = "Lambda@Edge or CloudFront Function associations for the default cache behavior."
  type = list(object({
    event_type   = string
    function_arn = string
  }))
  default = []

  validation {
    condition = length([
      for association in var.function_associations : association.event_type
      if !contains(["viewer-request", "viewer-response", "origin-request", "origin-response"], association.event_type)
    ]) == 0
    error_message = "function_associations.event_type must be viewer-request, viewer-response, origin-request, or origin-response."
  }
}

variable "custom_error_responses" {
  description = "Custom error responses for the distribution."
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for custom domain aliases."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version when using a custom ACM certificate."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "ssl_support_method" {
  description = "SSL support method when using a custom ACM certificate."
  type        = string
  default     = "sni-only"

  validation {
    condition     = contains(["sni-only", "vip"], var.ssl_support_method)
    error_message = "ssl_support_method must be sni-only or vip."
  }
}

variable "geo_restriction_type" {
  description = "Geo restriction type for the distribution."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction."
  type        = list(string)
  default     = []
}

variable "logging_config" {
  description = "Standard access logging configuration. Set to null to disable."
  type = object({
    bucket          = string
    prefix          = optional(string, "")
    include_cookies = optional(bool, false)
  })
  default = null
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ARN or ID to associate with the distribution."
  type        = string
  default     = null
}

variable "http_version" {
  description = "Maximum HTTP version supported by the distribution."
  type        = string
  default     = "http2"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version must be http1.1, http2, http2and3, or http3."
  }
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
