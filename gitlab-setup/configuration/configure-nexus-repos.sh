#!/bin/bash
# EXECUTE THIS SCRIPT ON THE NEXUS SERVER AFTER NEXUS IS RUNNING

# This script uses Nexus REST API to configure repositories
NEXUS_URL="http://localhost:8081"
USERNAME="admin"
PASSWORD="admin123"  # Default password - get actual password from /opt/sonatype-work/nexus3/admin.password for newer versions

# Wait for Nexus to be fully up and running
echo "Waiting for Nexus to start up completely..."
until curl -s -f ${NEXUS_URL}/service/rest/v1/status > /dev/null; do
  echo "Waiting for Nexus API to become available..."
  sleep 10
done
echo "Nexus API is available!"

# Function to create repository
create_repo() {
  local repo_type=$1
  local repo_name=$2
  local blob_store=$3
  
  case $repo_type in
    docker-hosted)
      curl -k -v -X POST "${NEXUS_URL}/service/rest/v1/repositories/docker/hosted" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n ${USERNAME}:${PASSWORD} | base64)" \
        -d "{ \"name\": \"${repo_name}\", \"online\": true, \"storage\": { \"blobStoreName\": \"${blob_store}\", \"strictContentTypeValidation\": true, \"writePolicy\": \"ALLOW\" }, \"docker\": { \"v1Enabled\": false, \"forceBasicAuth\": true, \"httpPort\": 8082 } }"
      ;;
    maven-hosted)
      curl -k -v -X POST "${NEXUS_URL}/service/rest/v1/repositories/maven/hosted" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n ${USERNAME}:${PASSWORD} | base64)" \
        -d "{ \"name\": \"${repo_name}\", \"online\": true, \"storage\": { \"blobStoreName\": \"${blob_store}\", \"strictContentTypeValidation\": true, \"writePolicy\": \"ALLOW\" }, \"maven\": { \"versionPolicy\": \"RELEASE\", \"layoutPolicy\": \"STRICT\" } }"
      ;;
    maven-proxy)
      curl -k -v -X POST "${NEXUS_URL}/service/rest/v1/repositories/maven/proxy" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Basic $(echo -n ${USERNAME}:${PASSWORD} | base64)" \
        -d "{ \"name\": \"${repo_name}\", \"online\": true, \"storage\": { \"blobStoreName\": \"${blob_store}\", \"strictContentTypeValidation\": true }, \"proxy\": { \"remoteUrl\": \"https://repo1.maven.org/maven2/\", \"contentMaxAge\": 1440, \"metadataMaxAge\": 1440 }, \"negativeCache\": { \"enabled\": true, \"timeToLive\": 1440 }, \"httpClient\": { \"blocked\": false, \"autoBlock\": true, \"connection\": { \"retries\": 0, \"userAgentSuffix\": \"string\", \"timeout\": 60, \"enableCircularRedirects\": false, \"enableCookies\": false, \"useTrustStore\": false } }, \"maven\": { \"versionPolicy\": \"RELEASE\", \"layoutPolicy\": \"STRICT\" } }"
      ;;
  esac
}

# Create repositories
echo "Creating Docker hosted repository..."
create_repo "docker-hosted" "docker-hosted" "default"

echo "Creating Maven hosted repository..."
create_repo "maven-hosted" "maven-releases" "default"

echo "Creating Maven proxy repository..."
create_repo "maven-proxy" "maven-central" "default"

echo "Nexus repositories configured successfully!"
echo "Access Nexus at: ${NEXUS_URL}"
echo "Default credentials: admin / admin123"
echo ""
echo "Available repositories:"
echo "- docker-hosted: Use port 8082 for Docker registry"
echo "- maven-releases: Use for storing Maven artifacts"
echo "- maven-central: Proxy for Maven Central repository" 