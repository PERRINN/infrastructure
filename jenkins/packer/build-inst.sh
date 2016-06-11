#!/bin/bash
#
sudo yum update -y
sudo rpm -i /tmp/jdk.rpm
sudo mkdir /opt/apache
sudo tar -xf /tmp/apache-maven-3.3.9-bin.tar.gz -C /opt/apache
sudo mv /opt/apache/apache-maven-3.3.9 /opt/apache/maven
sudo yum install -y gcc git

