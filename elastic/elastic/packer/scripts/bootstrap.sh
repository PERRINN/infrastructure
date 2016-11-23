#!/bin/bash
#
#resize2fs /dev/xvda1
#
sudo mkdir /opt/apache
sudo yum erase -y java-1.7.0-openjdk
sudo rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
sudo yum install -y newrelic-sysmond git java-1.8.0-openjdk
sudo yum groupinstall -y "Development Tools"
sudo rpm -i /tmp/jdk.rpm
sudo yum update -y 
sudo chkconfig newrelic-sysmond off
sudo wget -O /tmp/elasticsearch.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.0.1.tar.gz
sudo tar -xf /tmp/elasticsearch.tar.gz -C /opt
