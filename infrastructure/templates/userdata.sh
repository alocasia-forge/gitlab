#!/bin/bash
exec > >(tee /var/log/user-data.log)
exec 2>&1

# Update system packages
sudo apt-get update -y

# Install basic dependencies (awscli package n'existe pas sur Ubuntu 24.04)
sudo apt-get install -y jq postgresql-client curl unzip wget

# Install AWS CLI v2 (version correcte)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

# Export PATH pour que aws soit trouvé
export PATH=$PATH:/usr/local/bin

# Install/Update SSM Agent
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb

# Start and enable SSM Agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Extract hostname from endpoint (remove port if present)
RDS_HOST=$(echo "${rds_endpoint}" | cut -d':' -f1)

# Configure GitLab external URL and nginx for ALB 
sudo sed -i "s/postgresql\['enable'\] = true/postgresql['enable'] = false/" /etc/gitlab/gitlab.rb

sudo cat >> /etc/gitlab/gitlab.rb << EOF
external_url '${gitlab_external_url}'
nginx['listen_port'] = 80
nginx['listen_https'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = '$RDS_HOST'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = '${rds_database}'
gitlab_rails['db_password'] = '${rds_password}'
gitlab_rails['db_username'] = '${rds_username}'

gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']

gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "SSO Alocasia",
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://sso.matih.eu/realms/master",
      discovery: true,
      client_auth_method: "query",
      uid_field: "preferred_username",
      send_scope_to_token_endpoint: false,
      pkce: true,
      client_options: {
        identifier: "gitlab",
        secret: "<YOUR_CLIENT_SECRET>",
        redirect_uri: "https://git.matih.eu/users/auth/openid_connect/callback"
      }
    }
  }
]
EOF

# Reconfigure GitLab with new settings
echo "Configuring GitLab..."
sudo gitlab-ctl reconfigure

# Restart GitLab services
sudo gitlab-ctl restart

# Install CloudWatch agent for monitoring
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
