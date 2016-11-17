#!/bin/bash
#
VERSION="2"
BUILD="2"
AMI_NAME="jenkins-appserver-v${VERSION}-r${BUILD}"
REGION="ap-southeast-2"
AMI_DESC="amzn-ami-hvm-2016.09.0.20161028-x86_64-gp2"

echo "Figuring out:"
VPC=$(aws ec2 describe-vpcs --region ${REGION} --filters "Name=isDefault,Values=true" --output text --query 'Vpcs[*].{ID:VpcId}')
echo "VPC...${VPC}"
AZ=${REGION}b
echo "AZ...${AZ}"
SUBNET=$(aws ec2 describe-subnets --region ${REGION} --filters "Name=vpc-id,Values=${VPC}" "Name=availabilityZone,Values=${AZ}" --output text --query 'Subnets[0].{ID:SubnetId}')
echo "Subnet...${SUBNET}"
AMI=$(aws ec2 describe-images --region ${REGION} --filters "Name=name,Values=${AMI_DESC}" --output text --query 'Images[*].{ID:ImageId}')
echo "AMI...${AMI}"

# Generate a unique identified for this build. UUID is the easiest
uuid=$(date +"%s")

packer build \
	-var "build_uuid=${uuid}" \
	-var "aws_ami=${AMI}" \
	-var "aws_instance_type=t2.small" \
	-var "aws_instance_profile=packer-linux" \
	-var "aws_vpc_id=${VPC}" \
	-var "aws_subnet_id=${SUBNET}" \
	-var "aws_region=${REGION}" \
    -var "version=1" \
    -var "build=0" \
	-var "ami_name=${AMI_NAME}" \
	-var "aws_az=${AZ}" \
	ami.json
	
