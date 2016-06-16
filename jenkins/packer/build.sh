#!/bin/bash
#
packer -version || true
uuid = $(date +"%s")
AWS_REGIONNAME="ap-southeast-2"

packer build \
	-var "soe_version=0.1.0" \
	-var "build_number=1" \
	-var "build_uuid=${uuid}" \
	-var "aws_ami=ami-75e5cb16" \
	-var "aws_instance_type=t2.micro" \
	-var "aws_instance_profile=packer-linux" \
	-var "aws_vpc_id=VPC" \
	-var "aws_subnet_id=SUBNET" \
	-var "aws_region_name=${AWS_REGIONNAME}" 
	jenkins-base.json

