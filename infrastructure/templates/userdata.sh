#!/bin/bash

# Update system packages
apt-get update

# Install/Update SSM Agent
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb

# Start and enable SSM Agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Configure GitLab external URL and nginx for ALB
cat >> /etc/gitlab/gitlab.rb << EOF
external_url '${gitlab_external_url}'
nginx['listen_port'] = 80
nginx['listen_https'] = false
EOF

# Reconfigure GitLab with new settings
gitlab-ctl reconfigure

# Restart GitLab services
gitlab-ctl restart

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

echo "GitLab 18.0.2 configuration completed"
echo "SSM Agent installed and started"