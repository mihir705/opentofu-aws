# EKS Module

OpenTofu module to create an AWS EKS cluster with managed node groups, core add-ons, IAM roles, control plane logging, optional KMS encryption, and OIDC for IRSA.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `aws_eks_cluster` | Yes | Control plane |
| `aws_eks_node_group` | Yes | One per `node_groups` entry |
| `aws_eks_addon` | Yes | Defaults: vpc-cni, coredns, kube-proxy |
| `aws_iam_role` (cluster) | No | When `cluster_role_arn` is null |
| `aws_iam_role` (node) | No | When `node_role_arn` is null |
| `aws_cloudwatch_log_group` | No | When control plane logs enabled |
| `aws_iam_openid_connect_provider` | No | When `create_oidc_provider = true` |

## Requirements

| Name | Version |
|------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [AWS Provider](https://registry.opentofu.org/hashicorp/aws/latest) | >= 5.0 |
| [TLS Provider](https://registry.opentofu.org/hashicorp/tls/latest) | >= 4.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Basic cluster with managed nodes

```hcl
eks_clusters = {
  main = {
    name               = "my-company-prod"
    kubernetes_version = "1.31"

    vpc_key     = "main"
    subnet_keys = ["az-a", "az-b"]
    security_group_keys = ["eks"]

    node_groups = {
      general = {
        instance_types = ["t3.medium"]
        desired_size   = 2
        min_size       = 1
        max_size       = 4
      }
    }

    tags = { Purpose = "main-kubernetes" }
  }
}
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `name` | Cluster name | — |
| `kubernetes_version` | Control plane version | — |
| `subnet_ids` | Subnets (min 2 AZs) | — |
| `security_group_ids` | Additional cluster SGs | `[]` |
| `cluster_role_arn` | Existing cluster IAM role | auto-create |
| `node_role_arn` | Existing node IAM role | auto-create |
| `endpoint_private_access` | Private API endpoint | `true` |
| `endpoint_public_access` | Public API endpoint | `true` |
| `public_access_cidrs` | Allowed public API CIDRs | `["0.0.0.0/0"]` |
| `enabled_cluster_log_types` | Control plane logs | `["api","audit","authenticator"]` |
| `kms_key_id` | Encrypt Kubernetes secrets | `null` |
| `authentication_mode` | EKS access API mode | `API_AND_CONFIG_MAP` |
| `create_oidc_provider` | IRSA OIDC provider | `true` |
| `node_groups` | Managed node groups map | — |
| `addons` | EKS add-ons map | vpc-cni, coredns, kube-proxy |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | Cluster ARN |
| `cluster_endpoint` | API server endpoint |
| `cluster_certificate_authority_data` | CA data (sensitive) |
| `oidc_provider_arn` | IRSA OIDC provider ARN |
| `cluster_role_arn` / `node_role_arn` | IAM role ARNs |
| `node_group_arns` | Node group ARNs by key |

## Validation

The module includes **18 `check` blocks** for:

- Subnet count, endpoint access, and public CIDR rules
- Authentication mode and control plane log types
- Node group scaling, capacity types, disk size, taints, and update config
- IAM role name length limits for auto-created roles
- External IAM role ARN requirements
- Add-on conflict resolution settings
- CloudWatch log retention values

## Coverage matrix

| Capability | Supported | Notes |
|------------|-----------|-------|
| EKS control plane | Yes | `aws_eks_cluster` |
| Managed node groups | Yes | Multiple groups per cluster |
| Auto IAM roles | Yes | Cluster + node roles with standard policies |
| Custom IAM roles | Yes | `cluster_role_arn` / `node_role_arn` or `*_role_key` |
| Core add-ons | Yes | vpc-cni, coredns, kube-proxy (defaults) |
| Custom add-ons | Yes | ebs-csi-driver, etc. with IRSA role ARNs |
| OIDC / IRSA | Yes | `aws_iam_openid_connect_provider` |
| Control plane logs | Yes | CloudWatch with retention |
| KMS secrets encryption | Yes | `kms_key_id` / `kms_key_key` |
| EKS Access API | Yes | `authentication_mode`, bootstrap admin |
| Public / private API | Yes | Configurable endpoint access |
| SPOT node groups | Yes | With taints/labels |
| Fargate profiles | No | Use managed nodes or separate module |
| EKS access entries | No | Wire `aws_eks_access_entry` separately |
| Cluster autoscaler / Karpenter | No | Install post-provision |
| AWS Load Balancer Controller | No | Helm install post-provision |
| Pod Identity associations | No | IRSA via OIDC provider is supported |

## Environment wiring

| Key | Resolves to |
|-----|-------------|
| `vpc_key` + `subnet_keys` | Private subnet IDs |
| `security_group_keys` | Security group IDs |
| `kms_key_key` | KMS key ARN |
| `cluster_role_key` / `node_role_key` | IAM role ARNs |

## Notes

- Use **private subnets** for worker nodes; ensure NAT gateway is enabled in the VPC.
- After apply, configure `kubectl` with `aws eks update-kubeconfig --name <cluster>`.
- For EBS CSI and other IRSA add-ons, create IAM roles and pass `service_account_role_arn`.
- Restrict `public_access_cidrs` in production (avoid `0.0.0.0/0`).
- When using `kms_key_key`, ensure the KMS key policy allows the EKS service to use the key.
- Custom IAM roles must include standard EKS managed policies when not auto-created.
