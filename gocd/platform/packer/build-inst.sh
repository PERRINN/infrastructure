#!/bin/bash
#
sudo rpm -Uvh http://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm
sudo yum update -y aws-cfn-bootstrap
sudo yum erase -y java-1.7.0-openjdk
sudo yum install -y java-1.8.0-openjdk mysql tomcat8 tomcat8-webapps tomcat8-docs-webapp tomcat8-admin-webapps newrelic-sysmond rsyslog pystache
sudo yum update -y

sudo chkconfig tomcat8 off
sudo chkconfig newrelic-sysmond off
sudo chkconfig rsyslog off

