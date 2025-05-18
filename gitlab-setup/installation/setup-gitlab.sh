#!/bin/bash
# THIS SCRIPT RUNS ON THE GITLAB EC2 INSTANCE AS USER-DATA

# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y curl openssh-server ca-certificates tzdata perl postfix

# Add GitLab repository
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

# Install GitLab
EXTERNAL_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" \
  apt-get install gitlab-ce -y

# Wait for GitLab to be fully configured
echo "GitLab is being configured. Initial root password will be in /etc/gitlab/initial_root_password" 