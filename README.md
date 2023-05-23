# engagesretest

## Deploying

**Terraform deployment order:**

- locking
- vpc
- security groups
- rds
- app-ec2
- haproxy-ec2

To start create a Key Pair in AWS EC2 with the name "testing" and download the PEM file. The aws profile is set to default, so make sure your aws credentials are set to the account you want to deploy this to. Follow the order above and run `terraform init` then `terraform apply` in each directory starting at "locking" and "haproxy-ec2" last.

After all resources are deployed the **HAProxy** instance as a jumpbox to reach the **App-EC2s** in the private subnet. For access to the **App-EC2s** copy the testing.pem file to use inside the **HAProxy** instance.

To reach the app from a web browser copy and paste the **Public IPv4 DNS** name of the **HAProxy** instance into your browser.

## Infrastructure

![diagram](/diagram.png)

- The VPC is created with 2 different availability zones in us-east-1 both with public, private, and db subnets.

- The HAProxy server resides in the public subnet for access and use as a bastion host with only ports 80, 443, and 22 available.

- App-EC2s are deployed in the private subnet as they shouldn't be exposed to the public with traffic being directed through the HAProxy server, the security group for these instances only allows traffic over 443, 80, and 22 via the HAProxy server's security group.

- The Postgres RDS is a multi AZ RDS instance deployed in the dbsubnet with the secondary set to the other AZ, ingress rules are set to only allow traffic over 5432 from the App-EC2s security group.

- Logs for RDS and each EC2 are sent to CloudWatch logs, log groups: HAProxy-server, sreTestApp, /aws/rds/instance/sre-testapp-db/postgresql.

- All storage is set as encrypted at rest. For encryption in transit route53 hosted zone, record and wild card ssl certificate with certificate manager should be created. An A record for the HAProxy and 2 cname record internal routes for the ec2 instances.

### Security Groups

**<ins>RDS Ingress</ins>**
| | |
| ----------- | ----------- |
| Port | 5432 |
| Source | App-EC2-sg |
| Protocol | TCP |

**<ins>App-EC2 Ingress</ins>**
| | |
| ----------- | ----------- |
| Port | 80, 443, 22 |
| Source | HAProxy-sg |
| Protocol | TCP |

**<ins>HAProxy Ingress</ins>**
| | |
| ----------- | ----------- |
| Port | 80, 443, 22 |
| Source | All |
| Protocol | TCP |

## Recommended Infrastructure Changes

Substituing Nginx/HAProxy for ALB for better availability and easier configuration and control with terraform, container the app and deploy using ECS/EKS. There is a branch in this repo called ecs-infra that shows the initial concept of the terraform structure for this build out. It would also be helpful for the app to use an ORM like sequelize to create the table in the database.
