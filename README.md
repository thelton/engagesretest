# engagesretest

## Deploying

**Terraform deployment order:**
locking
vpc
security groups
rds
app-ec2
haproxy-ec2

To start create a Key Pair in AWS EC2 with the name "testing" and download the PEM file. The aws profile is set to default so make sure your aws credentials are set to the account you want to deploy this to. Follow the order above and run `terraform init` then `terraform apply` in each directory.
After all resources are deployed, use the **HAProxy** instance as a jumpbox to reach the app EC2s in the private subnet. Copy the testing.pem file to use inside the HAProxy. When connected to the one of the **app-ec2** instances run `chmod +x launch.sh` and then execute the launch script, `./launch.sh`. The launch script will deploy the app and nginx and a postgres instance for seeding the rds database. User docker ps and `docker exec -it POSTGRESS_CONTAINER_ID sh`, in the container and run

```
CREATE TABLE IF NOT EXISTS students (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255), age INT, DOB DATE); ALTER TABLE students OWNER to pguser;
```

To reach the app from a web browser copy and paste the **Public IPv4 DNS** name of the **HAProxy** instance into your browser.

## Infrastructure

![diagram](/diagram.png)

The VPC is created with 2 different availability zones in us-east-1 both with public, private, and db subnets. The HAProxy server residing in the public subnet for access and use as a bastion host with only ports 80, 443, and 22 available. App-ec2s are deployed in the private subnet as they shouldn't be exposed to the public with being directed through the HAProxy server, the security group for these only allows traffic over 443, 80, and 22 via the HAProxy server's security group. Postgres RDS is a multi AZ RDS instance deployed in the dbsubnet with the secondary set to the other AZ, ingress rules are set to only allow traffic over 5432 from the App-ec2s security group. All storage is set as encrypted at rest. Logs for RDS and each EC2 are sent to CloudWatch logs, log groups: HAProxy-server, sreTestApp, /aws/rds/instance/sre-testapp-db/postgresql.

## Recommended Infrastructure Changes

Substituing Nginx/HAProxy for ALB, container the app, and deploy using ECS/EKS. There is a branch called in this repo called ecs-infra that shows the initial concept of the terraform structure for this build out. It would also be helpful for the app to use an ORM like sequelize to create the table in the database.
