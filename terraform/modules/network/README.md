# Network Module

![Terraform Module](https://img.shields.io/badge/Terraform-Module-844FBA?logo=terraform&logoColor=white)
![AWS VPC](https://img.shields.io/badge/AWS%20VPC-Network%20Foundation-FF9900?logo=amazonaws&logoColor=white)
![Private Subnets](https://img.shields.io/badge/Subnets-Private%20Workers-111827)
![Load Balancers](https://img.shields.io/badge/Public%20Subnets-Load%20Balancers-2563EB)

Creates the VPC foundation for EKS:

## Learning Focus

| Topic | What this module teaches |
|---|---|
| Public/private split | Public subnets for load balancers, private subnets for worker nodes. |
| Egress design | NAT gateway tradeoffs between cost and availability. |
| Kubernetes discovery | AWS load balancer tags for Kubernetes subnets. |

- DNS-enabled VPC
- Public subnets for load balancers and NAT gateways
- Private subnets for EKS managed node groups
- Internet gateway, NAT gateway, and route tables
- Kubernetes discovery tags for AWS load balancers

For production, set `single_nat_gateway = false` to create one NAT gateway per AZ.
