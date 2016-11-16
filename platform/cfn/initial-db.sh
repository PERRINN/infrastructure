#!/bin/bash
#
VERSION="0"
BUILD="1"
REGION="ap-southeast-2"
AZ=${REGION}b 
CFNBUCKET="cm-devel-1"
PRODUCT="platform"
USER="DONTUSE"
PASSWORD="CHANGEME"
DBNAME="PERRINNAPP"
SNAPSHOTNAME="PERRINAPPBASE-v${VERSION}-r${BUILD}"
URL=https://s3-${REGION}.amazonaws.com/${CFNBUCKET}/${PRODUCT}

echo ${URL}

aws s3 cp initial-database.json s3://${CFNBUCKET}/${PRODUCT}/initial-database.json
aws s3 cp initial-db-security.json s3://${CFNBUCKET}/${PRODUCT}/initial-db-security.json
aws s3 cp initial-database-instance.json s3://${CFNBUCKET}/${PRODUCT}/initial-database-instance.json

aws cloudformation create-stack --stack-name InitialDB \
    --template-url ${URL}/initial-database.json \
    --capabilities CAPABILITY_IAM \
    --parameters "ParameterKey=ScriptRegion,ParameterValue=${REGION}" \
        "ParameterKey=AdminCIDR,ParameterValue=1.129.96.165/3" \
        "ParameterKey=CfnBaseName,ParameterValue=${CFNBUCKET}" \
        "ParameterKey=CfnBucketName,ParameterValue=${PRODUCT}" \
        "ParameterKey=Database,ParameterValue=${DBNAME}" \
        "ParameterKey=DatabaseName,ParameterValue=${DBNAME}" \
        "ParameterKey=DatabaseInstanceClass,ParameterValue=db.t2.micro" \
        "ParameterKey=DatabasePassword,ParameterValue=${PASSWORD}" \
        "ParameterKey=DatabaseStorage,ParameterValue=5" \
        "ParameterKey=DatabaseUser,ParameterValue=${USER}"

aws cloudformation wait stack-create-complete --stack-name InitialDB

STACKID=$(aws cloudformation describe-stack-resources --stack-name InitialDB --logical-resource-id SQL --query 'StackResources[0].PhysicalResourceId' --output text)
RDSID=$(aws cloudformation describe-stacks --stack-name ${STACKID} --query 'Stacks[0].Outputs[?OutputKey==`DatabaseId`].OutputValue' --output text)
DBHOST=$(aws rds describe-db-instances --db-instance-identifier ${RDSID} --query 'DBInstances[0].Endpoint.Address')

perrinnapp-db-load --db-host ${DBHOST} --db-name ${DBNAME} --user-name ${USER} --password ${PASSWORD}

aws rds create-db-snapshot --db-instance-identifier ${RDSID} --db-snapshot-identifier ${SNAPSHOTNAME}

aws rds wait db-snapshot-completed --db-snapshot-identifier ${SNAPSHOTNAME}
