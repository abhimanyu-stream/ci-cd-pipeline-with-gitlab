#!/bin/bash
# THIS SCRIPT RUNS ON THE NEXUS EC2 INSTANCE AS USER-DATA

# Update system
apt-get update && apt-get upgrade -y

# Install Java
apt-get install -y openjdk-8-jdk

# Install necessary tools
apt-get install -y wget unzip

# Create nexus user
useradd -M -d /opt/nexus -s /bin/bash -r nexus

# Download and extract Nexus
cd /opt
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -xvf latest-unix.tar.gz
mv nexus-* nexus
rm latest-unix.tar.gz

# Set permissions
chown -R nexus:nexus /opt/nexus
chown -R nexus:nexus /opt/sonatype-work

# Create service file
cat > /etc/systemd/system/nexus.service << 'EOF'
[Unit]
Description=Nexus Repository
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Nexus service
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

echo "Nexus installation complete. Access at http://YOUR_SERVER_IP:8081"
echo "Default credentials: admin / admin123" 