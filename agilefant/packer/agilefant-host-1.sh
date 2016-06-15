#!/bin/bash
#
packer -version || true

AWS_REGIONNAME="ap-southeast-2"

# Generate a unique identified for this build. UUID is the easiest
uuid=$(date +"%s")
if [ -f ami-id ]
then
	rm ami-id
fi

packer build \
	-var "soe_version=0.1.0" \
	-var "build_number=1" \
	-var "build_uuid=${uuid}" \
	-var "aws_source_ami=ami-75e5cb16" \
	-var "aws_instance_type=t2.small" \
	-var "aws_instance_profile=packer-linux" \
	-var "aws_vpc_id=vpc-7e9de01b" \
	-var "aws_subnet_id=subnet-8df9b6fa" \
	-var "aws_region=ap-southeast-2" \
	agilefant-base.json
