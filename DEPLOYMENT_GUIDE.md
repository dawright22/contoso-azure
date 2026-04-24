# Contoso Web on AWS - Terraform Deployment Guide

This Terraform configuration deploys the Azure-Samples/contoso-web application to AWS without the chat functionality.

## What Will Be Created

- **VPC** - Virtual Private Cloud with subnets and routing
- **EC2 Instance** - t3.micro Ubuntu 22.04 server with the Contoso web app
- **Application Load Balancer (ALB)** - Routes HTTP traffic to the application
- **Security Groups** - Controls inbound/outbound traffic
- **S3 Bucket** - For storing application artifacts
- **IAM Role & Policy** - EC2 instance permissions for S3 access
- **PM2 Process Manager** - Keeps the Next.js app running

## Prerequisites

1. AWS Account with appropriate credentials configured
2. Terraform >= 1.2
3. AWS CLI (optional, for debugging)

## Configuration

### Key Variables

Edit `variables.tf` to customize:

```hcl
region           = "us-west-1"      # AWS region
instance_type    = "t3.micro"       # EC2 instance type
app_name         = "contoso-web"    # Application name
app_artifact_path = "app/contoso-web.tar.gz"
node_env         = "production"     # Node environment
```

## Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply the Configuration

```bash
terraform apply
```

Terraform will:
- Create the AWS infrastructure
- Upload the local app archive to S3 (`app/contoso-web.tar.gz` by default)
- Download and extract the archive on EC2
- Install Node.js and dependencies
- Build the Next.js application
- Start the application with PM2

ALB setup note:
- The ALB is attached to two subnets in different Availability Zones, which is required for an internet-facing ALB.

### 4. Access the Application

After deployment completes, Terraform will output:

```
Outputs:
alb_url = "http://your-alb-dns-name.us-west-1.elb.amazonaws.com"
```

Use this URL to access the Contoso web application.

## Chat Functionality

The chat feature is **disabled by default** in this deployment:

1. **Environment Variables** - `.env.production` file created without chat endpoints
2. **Chat UI** - While the UI components remain, they won't function without the Azure AI Services endpoints

### To Enable Chat (Optional)

If you want to add chat functionality later:

1. Set up Azure services:
   - Azure AI Search
   - Azure AI Services
   - Prompt Flow

2. SSH into the EC2 instance:
   ```bash
   ssh -i your-key.pem ubuntu@<instance-public-ip>
   ```

3. Update `.env.production`:
   ```bash
   cd /opt/contoso-web
   sudo nano .env.production
   # Add your Azure endpoints and keys
   ```

4. Restart the application:
   ```bash
   pm2 restart contoso-web
   ```

## Monitoring and Troubleshooting

### Connect to the Instance

```bash
# Get the public IP from Terraform outputs
ssh -i your-key.pem ubuntu@<instance-public-ip>
```

### View Application Logs

```bash
# PM2 logs
pm2 logs

# Application output log
tail -f /opt/contoso-web/logs/out.log

# Application error log
tail -f /opt/contoso-web/logs/error.log
```

### Restart the Application

```bash
pm2 restart contoso-web
```

### Check Application Status

```bash
pm2 status
```

### ALB 502 Bad Gateway

If the ALB returns `502`, verify target health and bootstrap output:

```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
sudo tail -n 200 /var/log/cloud-init-output.log
pm2 logs contoso-web
```

If `user_data.sh` changed, run `terraform apply` to replace the instance and re-run bootstrap.

## Cost Estimation

Estimated monthly costs (US West 1):
- **EC2 t3.micro**: ~$8
- **ALB**: ~$15
- **Data Transfer**: ~$10 (if applicable)
- **S3 Storage**: < $1

**Total: ~$34/month** (prices vary by region)

Accounts with free-tier or promotional credits may incur lower costs.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Customization

### Modify the Application

To remove chat-related UI components:

1. Connect to the instance
2. Edit files in `/opt/contoso-web/src/`
3. Comment out or remove chat-related components
4. Rebuild: `npm run build`
5. Restart: `pm2 restart contoso-web`

### Add SSL/HTTPS

1. Obtain an SSL certificate (AWS Certificate Manager or Let's Encrypt)
2. Add HTTPS listener to the ALB in `main.tf`
3. Set `enable_https = true` in `variables.tf`
4. Run `terraform plan` and `terraform apply`

### Scale the Application

- Change `instance_type` to a larger size
- Use EC2 Auto Scaling Group with the ALB
- Add CloudFront CDN for static assets

## Next Steps

1. Deploy to production
2. Configure custom domain (Route 53 + domain registrar)
3. Set up CloudWatch monitoring and alerts
4. Implement CI/CD pipeline (CodePipeline, GitHub Actions)
5. Set up database if needed (RDS, DynamoDB)

## Support

For issues with:
- **Terraform**: Check terraform.io documentation
- **AWS**: Review AWS console or run `aws logs tail` commands
- **Contoso Web App**: See https://github.com/Azure-Samples/contoso-web

## License

This Terraform configuration is provided as-is. The Contoso web application is licensed under MIT.
