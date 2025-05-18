#!/bin/bash
# EXECUTE THIS SCRIPT ON THE GITLAB SERVER AFTER INSTALLATION

# Configure GitLab settings
echo "Configuring GitLab CI/CD settings..."

# Get the GitLab root password
ROOT_PASSWORD=$(grep -A 3 "Password:" /etc/gitlab/initial_root_password | tail -1)
echo "Root password: $ROOT_PASSWORD"

# Create a personal access token for API access
echo "To create a Personal Access Token, log in to GitLab UI and go to User Settings > Access Tokens"
echo "Create a token with 'api' scope and save it for use with Jenkins"

# Create a sample project structure
mkdir -p /tmp/k8s-app
cd /tmp/k8s-app

# Create a Dockerfile
cat > Dockerfile << 'EOF'
FROM openjdk:17-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# Create .gitlab-ci.yml for GitLab CI
cat > .gitlab-ci.yml << 'EOF'
stages:
  - build
  - test
  - publish
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

build:
  stage: build
  image: maven:3.8-openjdk-11
  script:
    - mvn clean package
  artifacts:
    paths:
      - target/*.jar

test:
  stage: test
  image: maven:3.8-openjdk-11
  script:
    - mvn test

trivy-scan:
  stage: test
  image: aquasec/trivy:latest
  script:
    - trivy filesystem --exit-code 1 --severity HIGH,CRITICAL .

# This job would be executed by Jenkins via GitLab webhook
jenkins-pipeline:
  stage: deploy
  script:
    - echo "This job triggers Jenkins pipeline via webhook"
  when: manual
EOF

# Create a sample README
cat > README.md << 'EOF'
# Kubernetes Application

This is a sample application for Kubernetes deployment with GitLab CI/CD and Jenkins integration.

## Features

- GitLab CI/CD integration
- Jenkins pipeline for deployment
- Trivy for security scanning
- Nexus for artifact storage
- Kubernetes deployment
EOF

# Create a sample pom.xml
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>k8s-app</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>2.7.0</version>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>2.7.0</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Create sample Java source code
mkdir -p src/main/java/com/example/app
cat > src/main/java/com/example/app/Application.java << 'EOF'
package com.example.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @GetMapping("/")
    public String home() {
        return "Hello Kubernetes!";
    }
}
EOF

# Create Jenkins pipeline file for reference
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'my-app:latest'
        NEXUS_URL = 'http://nexus-server:8081'
        GITLAB_URL = 'http://gitlab-server'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }
        
        stage('Scan with Trivy') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE}'
            }
        }
        
        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh '''
                    docker tag ${DOCKER_IMAGE} ${NEXUS_URL}/repository/docker-hosted/${DOCKER_IMAGE}
                    echo ${NEXUS_PASS} | docker login -u ${NEXUS_USER} --password-stdin ${NEXUS_URL}
                    docker push ${NEXUS_URL}/repository/docker-hosted/${DOCKER_IMAGE}
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubernetes-config']) {
                    sh '''
                    kubectl set image deployment/my-app my-app=${NEXUS_URL}/repository/docker-hosted/${DOCKER_IMAGE} -n my-app
                    kubectl rollout status deployment/my-app -n my-app
                    '''
                }
            }
        }
    }
}
EOF

# Create sample Kubernetes deployment manifests
mkdir -p k8s
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nexus-server:8081/repository/docker-hosted/my-app:latest
        ports:
        - containerPort: 8080
EOF

cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

echo "Sample GitLab project structure created in /tmp/k8s-app"
echo "To create a new project in GitLab:"
echo "1. Log in to GitLab UI"
echo "2. Create a new project"
echo "3. Push this sample code to the new repository"
echo "4. Configure Jenkins webhook in GitLab project settings" 