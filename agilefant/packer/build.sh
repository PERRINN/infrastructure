#!/bin/bash
#
# If you deploy OUTSIDE ap-southeast-2, you
# need to change the ami ID
#
packer -version || true

AWS_REGIONNAME="ap-southeast-2"

# Generate a unique identified for this build. UUID is the easiest
uuid=$(date +"%s")
ver="0.1.0"
build="1"
stamp=`date -u +"%Y-%m-%dT%H-%M-%SZ"`

if [ -f ami-id ]
then
	rm ami-id
fi
if [ -f new_ami ]
then
	rm new_ami
fi

longname=0.1.0-${build}-awsafant-soe-${stamp}

packer build \
	-var "soe_version=${ver}" \
	-var "build_number=${build}" \
	-var "build_uuid=${uuid}" \
	-var "build_stamp=${stamp}" \
	-var "aws_source_ami=ami-75e5cb16" \
	-var "aws_instance_type=t2.small" \
	-var "aws_instance_profile=packer-linux" \
	-var "aws_vpc_id=vpc-7" \
	-var "aws_subnet_id=subnet-8" \
	-var "aws_region=ap-southeast-2" \
	agilefant-base.json
#
aws ec2 describe-images --filters "Name=name,Values=${longname}" | grep ImageId | awk '{ print $2}' | sed -e 's/"//g' | sed -e 's/,//' > new_ami

