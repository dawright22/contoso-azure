# Contoso Web on AWS - Quick Start Guide

## Overview

This Terraform configuration deploys the Contoso web website to AWS infrastructure with **chat functionality disabled by default**.

### What You Get

```
┌──────────────────────────────────────────────────────┐
│         Application Load Balancer (Port 80)          │
├──────────────────────────────────────────────────────┤
│                    ↓                                  │
│            EC2 Instance (t3.micro)                   │
│          - Ubuntu 22.04 LTS                          │
│          - Node.js 20.x                              │
│          - Next.js Application                       │
│          - PM2 Process Manager                       │
├──────────────────────────────────────────────────────┤
│   VPC (10.0.0.0/16) | S3 Bucket | Security Groups   │
└──────────────────────────────────────────────────────┘
```

## 5-Minute Deployment

### 1. Verify Prerequisites

```bash
# Check you have these installed
terraform version     # >= 1.2
aws --version        # AWS CLI configured with credentials
```

### 2. Configure (Optional)

```bash
# Edit variables if needed
nano variables.tf

# Key options:
# - region: AWS region (default: us-west-1)
# - instance_type: EC2 size (default: t3.micro)
# - app_name: Application name (default: contoso-web)
```

The load balancer is configured across two subnets in different Availability Zones, which is required for an internet-facing ALB.

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy everything
terraform apply

# Wait 3-5 minutes for the instance to deploy...
```

### 4. Access Application

```bash
# Get the application URL
terraform output alb_url

# Output example:
# http://contoso-web-alb-123456789.us-west-1.elb.amazonaws.com
```

**Copy the URL into your browser to access the Contoso web application!**

## File Guide

| File | Purpose |
|------|---------|
| `main.tf` | AWS infrastructure (VPC, EC2, ALB, S3, IAM) |
| `variables.tf` | Configuration variables |
| `outputs.tf` | Outputs after deployment |
| `terraform.tf` | Terraform version and provider config |
| `user_data.sh` | Deployment script (runs on EC2) |
| `DEPLOYMENT_GUIDE.md` | Detailed deployment documentation |
| `CHAT_DISABLING_OPTIONS.md` | Options for disabling chat |
| `disable-chat.sh` | Utility to remove chat UI components |

## Chat Functionality Status

| Feature | Status | Details |
|---------|--------|---------|
| Website Display | ✓ Enabled | Full website loads and displays |
| Chat UI Button | ✓ Visible | Chat button appears but doesn't work |
| Chat API Calls | ✗ Disabled | No Azure AI Services configured |
| Static Content | ✓ Enabled | All pages, images, CSS work |

### To Enable Chat Later

1. Set up Azure services (Search, AI Services, Prompt Flow)
2. SSH into the instance
3. Edit `/opt/contoso-web/.env.production`
4. Add your Azure credentials
5. Restart: `pm2 restart contoso-web`

See `CHAT_DISABLING_OPTIONS.md` for details.

## Common Commands

### Deployment Operations

```bash
# View the deployment plan
terraform plan

# Apply/deploy
terraform apply

# Destroy all resources
terraform destroy

# See all outputs
terraform output

# See specific output
terraform output alb_url
```

### Access the Instance

```bash
# Get instance IP
EC2_IP=$(terraform output instance_public_ip -raw)

# SSH into the instance
ssh -i ~/.ssh/your-key.pem ubuntu@$EC2_IP
```

### Monitor the Application

```bash
# SSH into instance first
ssh -i ~/.ssh/your-key.pem ubuntu@<instance-ip>

# View live logs
pm2 logs contoso-web

# View application output
tail -f /opt/contoso-web/logs/out.log

# Check application status
pm2 status

# Restart application
pm2 restart contoso-web

# Stop application
pm2 stop contoso-web

# Start application
pm2 start contoso-web
```

### Disable Chat Components

```bash
# SSH into instance
ssh -i ~/.ssh/your-key.pem ubuntu@<instance-ip>

# Run the disable-chat script
cd /opt/contoso-web
sudo bash disable-chat.sh
```

## Cost Breakdown (Monthly)

| Service | Estimated Cost |
|---------|---|
| EC2 t3.micro | $8 |
| Application Load Balancer | $15 |
| S3 Storage | $1 |
| Data Transfer | $10* |
| **Total** | **~$34** |

*Costs vary by region, traffic, and account-level credits/free-tier eligibility

## Troubleshooting

### Application Won't Load

```bash
# SSH into instance
ssh -i ~/.ssh/your-key.pem ubuntu@<instance-ip>

# Check logs
pm2 logs contoso-web

# Check if running
pm2 status

# Restart
pm2 restart contoso-web
```

### ALB Returns 502 Bad Gateway

```bash
# Verify target health in AWS
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check bootstrap and app logs on the instance
sudo tail -n 200 /var/log/cloud-init-output.log
pm2 logs contoso-web
```

If bootstrap changed (for example `user_data.sh`), re-run `terraform apply`. The EC2 instance is configured to replace on user-data changes.

### Can't Connect via SSH

```bash
# Verify security group allows SSH (port 22)
# Check EC2 console → Security Groups → Edit Inbound Rules

# Ensure your IP is authorized
# Allow your IP: YOUR_IP/32 on port 22
```

### Slow Performance

```bash
# Change instance type to larger
nano variables.tf
# Change: instance_type = "t3.large"

terraform apply
```

### Certificate/HTTPS

```bash
# Get SSL certificate (AWS Certificate Manager)
# Add HTTPS listener to ALB in main.tf
# Set: enable_https = true in variables.tf
# Re-run: terraform apply
```

## Security Notes

⚠️ **Important**: This setup is for development/demo purposes.

For production:
- [ ] Enable HTTPS/TLS
- [ ] Set up VPN or restrict SSH access
- [ ] Use AWS Secrets Manager for credentials
- [ ] Enable CloudWatch monitoring and alarms
- [ ] Implement auto-scaling
- [ ] Set up backup/disaster recovery

## Next Steps

1. **Access the Application**: Use the `alb_url` output
2. **Customize**: Modify the website code in the EC2 instance
3. **Add Authentication**: Implement user login
4. **Add a Database**: RDS PostgreSQL or DynamoDB
5. **Enable Chat** (optional): Configure Azure endpoints
6. **Production Ready**: HTTPS, monitoring, backups

## Files Modified/Created

```
learn-terraform/
├── main.tf                    (MODIFIED - Enhanced with full AWS infrastructure)
├── variables.tf               (MODIFIED - Added app-specific variables)
├── outputs.tf                 (MODIFIED - Added ALB, VPC, S3 outputs)
├── terraform.tf               (unchanged)
├── user_data.sh               (NEW - Deployment script)
├── disable-chat.sh            (NEW - Utility to remove chat UI)
├── DEPLOYMENT_GUIDE.md        (NEW - Detailed guide)
├── CHAT_DISABLING_OPTIONS.md  (NEW - Chat disabling reference)
└── QUICK_START.md             (this file)
```

## Support & Resources

- **Contoso Web Repo**: https://github.com/Azure-Samples/contoso-web
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS EC2**: https://docs.aws.amazon.com/ec2/
- **Next.js**: https://nextjs.org/docs

---

**Ready to deploy?** → Run `terraform apply` now! 🚀
