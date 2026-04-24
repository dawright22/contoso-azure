# Contoso Web on AWS - Terraform Deployment

Deploy the **Contoso Outdoors Company** website to AWS using Terraform, with **chat functionality disabled by default**.

This configuration creates a fully managed infrastructure on AWS to host the Next.js-based Contoso web application.

## What will this do?

This Terraform configuration creates:

- **VPC & Networking** - Virtual Private Cloud with subnets, routing, and security groups
- **EC2 Instance** - Ubuntu 22.04 server with Node.js and the Contoso web application
- **Application Load Balancer** - Routes HTTP traffic to your application
- **S3 Bucket** - Stores application artifacts
- **IAM Roles & Policies** - Secure permissions for EC2 instance
- **Process Manager** - PM2 keeps the application running and auto-restarts

## What are the prerequisites?

1. **AWS Account** - With appropriate IAM permissions to create EC2, VPC, ALB, S3, and IAM resources
2. **Terraform** - Version 1.2 or higher
3. **AWS Credentials** - Configured locally (`~/.aws/credentials` or environment variables)

For HCP Terraform: You must have an AWS account and provide your AWS Access Key ID and AWS Secret Access Key to HCP Terraform. HCP Terraform encrypts and stores variables using [Vault](https://www.vaultproject.io/). For more information, see [HCP Terraform variable documentation](https://www.terraform.io/docs/cloud/workspaces/variables.html).

## Quick Start

```bash
# 1. Initialize Terraform
terraform init

# 2. Review what will be created
terraform plan

# 3. Deploy to AWS
terraform apply

# 4. Get your application URL
terraform output alb_url
```

After 3-5 minutes, your Contoso web application will be live at the ALB URL!

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - 5-minute deployment guide (START HERE)
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Comprehensive deployment and troubleshooting
- **[CHAT_DISABLING_OPTIONS.md](CHAT_DISABLING_OPTIONS.md)** - Chat functionality configuration options

## Chat Functionality

**Status**: Disabled by default (no Azure AI Services endpoints configured)

The website displays fully functional except for chat features. To enable chat later, you'll need to:
1. Set up Azure services (Search, AI Services, Prompt Flow)
2. Configure environment variables
3. Restart the application

See [CHAT_DISABLING_OPTIONS.md](CHAT_DISABLING_OPTIONS.md) for details.

## File Structure

```
.
├── main.tf                      # AWS infrastructure code
├── variables.tf                 # Configuration variables
├── outputs.tf                   # Output values (URLs, IPs, etc.)
├── terraform.tf                 # Provider configuration
├── user_data.sh                 # EC2 deployment script
├── disable-chat.sh              # Optional: remove chat UI components
├── QUICK_START.md               # Quick deployment guide
├── DEPLOYMENT_GUIDE.md          # Detailed guide with monitoring
├── CHAT_DISABLING_OPTIONS.md    # Chat disabling reference
└── README.md                    # This file
```

## Next Steps

1. **Read** [QUICK_START.md](QUICK_START.md) for immediate deployment
2. **Configure** variables in `variables.tf` if needed (region, instance size, etc.)
3. **Deploy** with `terraform apply`
4. **Access** your application using the `alb_url` output
5. **Explore** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for monitoring and customization

## Support

- **Contoso Web Application**: https://github.com/Azure-Samples/contoso-web
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Next.js Documentation**: https://nextjs.org/docs

---

**Ready?** → Open [QUICK_START.md](QUICK_START.md) to get started! 🚀
