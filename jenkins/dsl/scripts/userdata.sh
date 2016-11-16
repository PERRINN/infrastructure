#!/bin/bash -v
#
yum update -y aws-cfn-bootstrap
# Install the files and packages from the metadata
/opt/aws/bin/cfn-init -v --stack {{ aws_stack_name() }} --resource JenkinsLaunchConfig --configsets InstallAndRun --region {{ ref('AWS::Region') }}
