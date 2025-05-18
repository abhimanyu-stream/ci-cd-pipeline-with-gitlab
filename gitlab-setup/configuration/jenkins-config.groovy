#!/usr/bin/env groovy
// PLACE THIS FILE IN: /var/lib/jenkins/init.groovy.d/ ON THE JENKINS SERVER

import jenkins.model.*
import hudson.security.*
import jenkins.install.*
import jenkins.security.s2m.AdminWhitelistRule
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.plugins.sonar.*
import hudson.tools.*
import hudson.plugins.git.*

// Disable setup wizard
def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

// Security setup - create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Allow Jenkins to use scripts approved by admin
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// Set number of executors
instance.setNumExecutors(5)

// Configure GitLab credentials
def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def gitlabCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  'gitlab-credentials',
  'GitLab Credentials',
  'gitlabuser',
  'gitlabpassword'
)
store.addCredentials(domain, gitlabCredentials)

// Configure Nexus credentials
def nexusCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  'nexus-credentials',
  'Nexus Repository Credentials',
  'admin',
  'admin123'
)
store.addCredentials(domain, nexusCredentials)

// Configure SonarQube
def sonarConfig = instance.getDescriptor(SonarGlobalConfiguration.class)
def sonarInstallation = new SonarInstallation(
  'SonarQube',
  'http://sonarqube-server:9000',
  'sonarqube-token',
  '',
  '',
  '',
  '',
  ''
)
sonarConfig.setInstallations(sonarInstallation)

// Configure Git
def gitDesc = instance.getDescriptor(GitTool.class)
def gitInst = new GitTool(
  'Default',
  '/usr/bin/git',
  null
)
gitDesc.setInstallations(gitInst)

// Save configuration
instance.save() 