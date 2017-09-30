#!/bin/bash
#
VERSION="2"
BUILD="2"
AMI_NAME="jenkins-appserver-v${VERSION}-r${BUILD}"
REGION="us-east-1"
PROFILE="versent.cfn"
AMI_DESC="amzn-ami-hvm-2017.03.1.20170812-x86_64-gp2"

echo "Figuring out:"
VPC=$(aws ec2 describe-vpcs --region ${REGION} --filters "Name=isDefault,Values=true" --output text --query 'Vpcs[*].{ID:VpcId}' --profile ${PROFILE})
echo "VPC...${VPC}"
AZ=${REGION}b
echo "AZ...${AZ}"
SUBNET=$(aws ec2 describe-subnets --region ${REGION} --filters "Name=vpc-id,Values=${VPC}" "Name=availabilityZone,Values=${AZ}" --output text --query 'Subnets[0].{ID:SubnetId}' --profile ${PROFILE})
echo "Subnet...${SUBNET}"
AMI=$(aws ec2 describe-images --region ${REGION} --filters "Name=name,Values=${AMI_DESC}" --output text --query 'Images[*].{ID:ImageId}' --profile ${PROFILE})
echo "AMI...${AMI}"


packer build \
	-var "build_uuid=${uuid}" \
	-var "aws_ami=${AMI}" \
	-var "aws_instance_type=t2.small" \
	-var "aws_instance_profile=packer-linux" \
	-var "aws_vpc_id=${VPC}" \
	-var "aws_subnet_id=${SUBNET}" \
	-var "aws_region=${REGION}" \
    -var "version=${VERSION}" \
    -var "build=${BUILD}" \
	-var "ami_name=${AMI_NAME}" \
	-var "aws_az=${AZ}" \
	ami-local.json
	
