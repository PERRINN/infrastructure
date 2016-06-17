#!/bin/bash
#
sudo yum update -y aws-cfn-bootstrap
sudo yum update -y
sudo rpm -i /tmp/jdk.rpm
sudo mkdir /opt/apache
sudo tar -xf /tmp/apache-maven.tar.gz -C /opt/apache
sudo mv /opt/apache/apache-maven-3.3.9 /opt/apache/maven
sudo mv /tmp/gocd.repo /etc/yum.repos.d/gocd.repo
sudo yum install -y go-server go-server unzip zip gcc git
sudo rpm -i /tmp/jenkins.rpm
cd /tmp; unzip packer.zip
sudo mv /tmp/packer /usr/local/bin/packer


