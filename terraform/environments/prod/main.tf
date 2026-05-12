module "network" {
  source = "../../modules/network"

  name                 = local.name_prefix
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name              = local.cluster_name
  cluster_version           = var.cluster_version
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  endpoint_public_access    = var.endpoint_public_access
  endpoint_private_access   = var.endpoint_private_access
  public_access_cidrs       = var.public_access_cidrs
  node_groups               = var.node_groups
  enable_secrets_encryption = var.enable_secrets_encryption
  tags                      = local.common_tags
}
