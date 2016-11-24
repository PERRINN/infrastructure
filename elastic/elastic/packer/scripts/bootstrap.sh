#!/bin/bash
#
#resize2fs /dev/xvda1
#
sudo mkdir /opt/apache
sudo yum erase -y java-1.7.0-openjdk
sudo rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
sudo yum install -y newrelic-sysmond git java-1.8.0-openjdk
sudo yum update -y 
sudo chkconfig newrelic-sysmond off
sudo wget -O /tmp/elasticsearch.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.0.1.tar.gz
sudo wget -O/tmp/x-pack.zip https://artifacts.elastic.co/downloads/packs/x-pack/x-pack-5.0.1.zip
sudo groupadd elastic
sudo useradd -c "Elastic Search" -d /opt/elasticsearch-5.0.1 -g elastic -s /bin/bash elastic
sudo tar -xf /tmp/elasticsearch.tar.gz -C /opt
sudo mv /tmp/sysctl.conf /etc/sysctl.conf
sudo mv /tmp/limits.conf /etc/security/limits.conf
sudo chown -R elastic:elastic /opt/elasticsearch-5.0.1

