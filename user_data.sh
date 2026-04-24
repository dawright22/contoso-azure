#!/bin/bash
set -e

# User Data Script for Contoso Web Deployment
# This script deploys the Contoso web application to the EC2 instance

echo "Starting Contoso Web deployment..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs awscli

# Install PM2 for process management
npm install -g pm2

# Create application directory
mkdir -p /opt/${app_name}
cd /opt/${app_name}

# Fetch the application package from the private S3 artifact bucket.
echo "Fetching application archive from s3://${artifact_bucket}/${artifact_key}..."
aws s3 cp "s3://${artifact_bucket}/${artifact_key}" ./app.tar.gz
tar -xzf ./app.tar.gz --strip-components=1
rm -f ./app.tar.gz
echo "Application archive extracted successfully"

# Disable chat functionality by modifying environment
# Create .env file without chat endpoints
cat > .env.production << EOF
# Contoso Web Configuration (Chat disabled)
NODE_ENV=${node_env}
EOF

# Install dependencies
echo "Installing Node.js dependencies..."
npm ci

# Build the Next.js application
echo "Building Next.js application..."
npm run build

# Create PM2 ecosystem configuration
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '${app_name}',
    script: 'node_modules/.bin/next',
    args: 'start',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: '${node_env}',
      PORT: 3000
    },
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF

# Create logs directory
mkdir -p ./logs

# Start application with PM2
echo "Starting ${app_name} application with PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Enable PM2 to start on boot
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u root --hp /root

# Print deployment summary
echo "========================================="
echo "Contoso Web deployment completed!"
echo "========================================="
echo "Application: ${app_name}"
echo "Node Environment: ${node_env}"
echo "Application Directory: /opt/${app_name}"
echo "Port: 3000 (via ALB on port 80)"
echo "PM2 Status: $(pm2 status)"
echo ""
echo "To view logs:"
echo "  PM2: pm2 logs"
echo "  Application logs: cat /opt/${app_name}/logs/out.log"
echo ""
echo "Chat functionality has been disabled."
echo "========================================="
