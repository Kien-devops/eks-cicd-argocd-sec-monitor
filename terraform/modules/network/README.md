# Network Module

Creates the VPC foundation for EKS:

- DNS-enabled VPC
- Public subnets for load balancers and NAT gateways
- Private subnets for EKS managed node groups
- Internet gateway, NAT gateway, and route tables
- Kubernetes discovery tags for AWS load balancers

For production, set `single_nat_gateway = false` to create one NAT gateway per AZ.

