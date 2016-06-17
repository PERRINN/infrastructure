#!/bin/bash
#
# $CFNLOC = the location of the CloudFormation scripts
#
AMI=`cat ../packer/new_ami`

aws cloudformation create-stack --stack-name platform \
--template-url https://s3-ap-southeast-2.amazonaws.com/cfnstore/platform/1.0.0/top.json \
--capabilities CAPABILITY_IAM \
--parameters "ParameterKey=AdminCIDR,ParameterValue=27.99.5.119/32" \
"ParameterKey=CfnBaseName,ParameterValue=perrinncfn" \
"ParameterKey=CfnBucketName,ParameterValue=platform" \
"ParameterKey=DatabaseInstanceClass,ParameterValue=db.t2.micro" \
"ParameterKey=DatabaseName,ParameterValue=platform" \
"ParameterKey=DatabasePassword,ParameterValue=P4$$w0rd" \
"ParameterKey=DatabaseStorage,ParameterValue=5" \
"ParameterKey=DatabaseUser,ParameterValue=afuser" \
"ParameterKey=DesiredUnits,ParameterValue=1" \
"ParameterKey=DnsDomain,ParameterValue=perrinapp.net" \
"ParameterKey=DnsId,ParameterValue=Z8" \
"ParameterKey=Environment,ParameterValue=test" \
"ParameterKey=KeyName,ParameterValue=afant.test" \
"ParameterKey=LinuxWebServerAmi,ParameterValue=${AMI}" \
"ParameterKey=LogglyHost,ParameterValue=logs-01.loggly.com:514" \
"ParameterKey=LogglyKey,ParameterValue=ce5" \
"ParameterKey=MaxUnits,ParameterValue=1" \
"ParameterKey=MinUnits,ParameterValue=1" \
"ParameterKey=NewRelicKey,ParameterValue=90" \
"ParameterKey=ScriptRegion,ParameterValue=ap-southeast-2" \
"ParameterKey=StackRelease,ParameterValue=1.0.0" \
"ParameterKey=WebServerInstanceType,ParameterValue=t2.micro" 


