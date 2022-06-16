# terraform-module-vault-lb
Terraform module to create the ALB for Vault

Inputs - Required:

 - `resource_tags` - AWS tags to apply to resources
 - `vpc_id` - AWS VPC Id
 - `subnet_ids` - The AWS Subnet Id to place the lb into     
 - `vault_domain` - url used for blacksmith domain
 - `route53_zone_id` - Route53 zone id
 - `security_groups` - Array of security groups to use on th elb
 - `vault_acm_arn` - ACM arn for the vault certificates

Inputs - Optional: 

 - `enable_route_53` - Disable if using CloudFlare or other DNS (default = 1, to disable, set = 0)
 - `internal_lb` - Determine whether the load balancer is internal-only facing (default = true)

Outputs:

 - `dns_name` - The A Record for the created load balancer