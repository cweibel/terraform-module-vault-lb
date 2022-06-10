variable subnet_ids            {}  # The AWS Subnet Id to place the lb into
variable resource_tags         {}  # AWS tags to apply to resources
variable vpc_id                {}  # The VPC Id
variable vault_domain          {}  # url used for vault domain
variable route53_zone_id       {}  # Route53 zone id
variable security_groups       {}  # Array of security groups to use
variable vault_acm_arn         {}  # ACM arn for the vault certificates

variable enable_route_53       { default = 1 }  # Disable if using CloudFlare or other DNS


################################################################################
# Vault ALB
################################################################################
resource "aws_lb" "vault_alb" {
  name               = "vault-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_groups
  tags               = merge({Name = "vault-alb"}, var.resource_tags)
}

################################################################################
# Vault ALB Target Group
################################################################################
resource "aws_lb_target_group" "vault_alb_tg" {
  name     = "vault-alb-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
  tags     = merge({Name = "vault-alb-tg"}, var.resource_tags)
  health_check {
    path = "/v1/sys/health"
    protocol = "HTTPS"
  }
}

################################################################################
# Vault ALB Target Group Attachment
################################################################################
# Define vault instances using instance group, can use instance_tags or filter
data "aws_instances" "vault_instances" {
  instance_tags = {
    instance_group = "vault"
  }
}
resource "aws_lb_target_group_attachment" "vault_alb_tga" {
  count            = length(data.aws_instances.vault_instances.ids)
  target_id        = data.aws_instances.vault_instances.ids[count.index]
  target_group_arn = aws_lb_target_group.vault_alb_tg.arn
  port             = 443
}

################################################################################
# Vault ALB Listeners - Vault API - HTTPS
################################################################################
resource "aws_alb_listener" "vault_alb_listener_443" {
  load_balancer_arn = aws_lb.vault_alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = var.vault_acm_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.vault_alb_tg.arn
  }
  tags = merge({Name = "vault-alb-listener-443"}, var.resource_tags)
}
################################################################################
# Vault ALB Listeners - Vault Strongbox API - HTTPS
################################################################################
resource "aws_alb_listener" "vault_alb_listener_8484" {
  load_balancer_arn = aws_lb.vault_alb.arn
  port = "8484"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = var.vault_acm_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.vault_alb_tg.arn
  }
  tags = merge({Name = "vault-alb-listener-8484"}, var.resource_tags)
}

################################################################################
# Vault ALB Route53 DNS
################################################################################
resource "aws_route53_record" "vault_alb_record" {

  count   = var.enable_route_53
  zone_id = var.route53_zone_id
  name    = var.vault_domain
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_lb.vault_alb.dns_name}"]
}

