# Contoso Web - Chat Disabling Configuration

This file provides options for disabling chat functionality in the Contoso web application on AWS.

## Option 1: Environment-Based Disabling (Default)

The deployment already does this by not setting chat-related environment variables in `.env.production`.

### Environment Variables

The following endpoints are NOT set in the deployment:
- `CONTOSO_SEARCH_ENDPOINT` - Azure Search service
- `CONTOSO_SEARCH_KEY` - Azure Search key
- `CONTOSO_AISERVICES_ENDPOINT` - Azure AI Services
- `CONTOSO_AISERVICES_KEY` - Azure AI Services key
- `PROMPTFLOW_ENDPOINT` - Prompt Flow endpoint
- `PROMPTFLOW_KEY` - Prompt Flow key
- `VISUAL_ENDPOINT` - Visual/Vision endpoint
- `VISUAL_KEY` - Vision key

Without these environment variables, the chat API calls will fail gracefully.

## Option 2: Code-Based Disabling

To completely remove chat functionality, modify the source code:

### Files to Modify

1. **Disable Chat API Routes**
   ```bash
   # On the EC2 instance
   ssh ubuntu@<instance-public-ip>
   cd /opt/contoso-web
   
   # Rename or remove API routes
   mv src/pages/api/chat src/pages/api/chat.disabled
   ```

2. **Remove Chat Components from UI**
   
   Edit `src/pages/index.tsx` or relevant component files:
   ```typescript
   // Comment out or remove:
   // import ChatComponent from '@/components/Chat';
   // <ChatComponent /> 
   ```

3. **Remove Chat-Related Dependencies**
   
   Edit `package.json`:
   ```bash
   cd /opt/contoso-web
   
   # Identify chat-related dependencies:
   npm list | grep -i chat
   
   # Remove if not needed:
   npm uninstall <package-name>
   npm run build
   ```

## Option 3: Reverse Proxy Configuration

If you want to serve the app but prevent chat API access at the ALB level:

### Add to ALB Listener Rules

```hcl
# Add to main.tf
resource "aws_lb_listener_rule" "block_chat_api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"Chat functionality is disabled\"}"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["/api/chat", "/api/chat/*"]
    }
  }
}
```

## Option 4: Complete Removal via Fork

Create a fork of the Contoso web repository without chat functionality:

```bash
# Clone, remove chat code, and push to your repo
git clone https://github.com/Azure-Samples/contoso-web.git my-contoso
cd my-contoso

# Remove chat-related files
rm -rf src/pages/api/chat
rm -rf src/components/Chat

# Remove from git
git rm -r src/pages/api/chat
git rm -r src/components/Chat

# Update package.json to remove chat dependencies
# Rebuild and test
npm ci
npm run build

# Push to your fork
git add .
git commit -m "Remove chat functionality"
git push origin main
```

Then update `variables.tf`:
```hcl
github_repo = "https://github.com/YOUR-USERNAME/contoso-web.git"
```

## Testing Chat Disabling

### Check Environment Variables

```bash
ssh ubuntu@<instance-public-ip>
cd /opt/contoso-web
env | grep -i contoso
# Should output: nothing (variables not set)
```

### Test API Endpoint

```bash
# Try to call chat API
curl http://<alb-dns-name>/api/chat

# Expected: 500 error or "Cannot POST" error
# This confirms chat endpoints are not functional
```

### Browser Test

1. Navigate to `http://<alb-dns-name>`
2. Look for chat button (may still be visible in UI)
3. Click chat button
4. Chat should fail to load or show error

## Reverting Changes

To re-enable chat functionality:

1. Add environment variables to `.env.production`:
   ```bash
   cd /opt/contoso-web
   nano .env.production
   ```

2. Add your Azure service credentials

3. Rebuild and restart:
   ```bash
   npm run build
   pm2 restart contoso-web
   ```

## Monitoring Chat Requests

### CloudWatch Logs

View failed chat API requests in CloudWatch:

```bash
# Add to Terraform to enable CloudWatch logs for ALB
resource "aws_lb" "main" {
  # ... existing config ...
  
  access_logs {
    bucket  = aws_s3_bucket.app_bucket.id
    enabled = true
  }
}
```

Then query:
```bash
aws logs tail /aws/alb/contoso-web --follow
```

## Best Practices

1. **Start with Option 1** - Default environment-based disabling is sufficient for most use cases
2. **Use Option 2** if you want to completely remove chat code before production
3. **Implement Option 3** if you need to block chat at the load balancer level
4. **Consider Option 4** for long-term maintenance and complete separation from Azure dependencies

## Security Considerations

- Disabling chat via environment variables is safe and reversible
- Ensure no sensitive Azure credentials are exposed in any config files
- Regularly update dependencies: `npm audit fix`
- Monitor logs for failed chat API calls (logs indicate someone tried to use chat)

## Support

For more information on the Contoso web application:
https://github.com/Azure-Samples/contoso-web

For AWS Terraform support:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs
