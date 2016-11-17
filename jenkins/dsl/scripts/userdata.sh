#!/bin/bash -v
#
chown -R tomcat:tomcat /usr/share/tomcat8
yum update -y aws-cfn-bootstrap
#
# Attach the network interface
#
INSTANCE_ID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 attach-network-interface --network-interface-id {{ ref('NetworkInterface') }} --instance-id $INSTANCE_ID --device-index 1 --region {{ref('AWS::Region')}}
# Install the files and packages from the metadata
/opt/aws/bin/cfn-init -v --stack {{ aws_stack_name() }} --resource JenkinsLaunchConfig --configsets InstallAndRun --region {{ ref('AWS::Region') }}
