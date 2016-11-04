#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'

template do

    value AWSTemplateFormatVersion: '2010-09-09'
    value Description: 'Jenkins Full Stack'

    parameter 'AccessCidr',
        Type: 'String',
        AllowedPattern: '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
        ConstraintDescription: 'must be a valid IP CIDR range of the form x.x.x.x/x.',
        Description: 'IP Range or Address allowed access to the instance',
        MaxLength: '18',
        MinLength: '9'

    parameter 'AccessSecurityGroup',
        Type: 'String',
        Description: 'Security Group ID for existing Access Control Group'

    parameter 'AccessSubnet',
        Type: 'String',
        AllowedPattern: 'subnet-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid subnet ID',
        Description: 'Subnet for the Access (Public) interface',
        MaxLength: '15',
        MinLength: '15'

    parameter 'AdminCidr',
        Type: 'String',
        AllowedPattern: '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
        ConstraintDescription: 'must be a valid IP CIDR range of the form x.x.x.x/x.',
        Description: 'IP Range or Address allowed administrative access to the instance',
        MaxLength: '18',
        MinLength: '9'

    parameter 'AdminSecurityGroup',
        Type: 'String',
        Description: 'Security Group ID for existing Access Control Group'

    parameter 'AdminSubnet',
        Type: 'String',
        AllowedPattern: 'subnet-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid subnet ID',
        Description: 'Subnet for the Admin interface',
        MaxLength: '15',
        MinLength: '15'

    parameter 'ServerAmi',
        Type: 'String',
        AllowedPattern: 'ami-[a-z0-9]{8}',
        MaxLength: '12',
        MinLength: '12',
        Default: 'ami-5180a746'

    parameter 'InstanceType',
        Type: 'String',
        Description: 'Instance Size for this machine',
        Default: 't2.small'

    parameter 'KeyName',
        Type: 'AWS::EC2::KeyPair::KeyName',
        ConstraintDescription: 'Must be a valid, existing Key Pair'

    parameter 'VpcId',
        Type: 'String',
        AllowedPattern: 'vpc-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid, existing VPC',
        MaxLength: '12',
        MinLength: '12'

    parameter 'ZoneName',
        Type: 'String',
        MinLength: '4',
        Default: 'oordas.net'

    condition 'AccessSecCond',
        equal(ref('AccessSecurityGroup'), '')

    condition 'AdminSecCond',
        equal(ref('AdminSecurityGroup'), '')
        

    resource 'AdminSecurity', Condition: 'AdminSecCond', Type: 'AWS::EC2::SecurityGroup', Properties: {
        GroupDescription: 'Access to management port on Jenkins Host',
        VpcId: ref('VpcId'),
        SecurityGroupIngress: [
            {
                CidrIp: ref('AdminCidr'),
                IpProtocol: 'tcp',
                FromPort: '22',
                ToPort: '22'
            }
        ]
    }

    resource 'AccessSecurity', Condition: 'AccessSecCond', Type: 'AWS::EC2::SecurityGroup', Properties: {
        GroupDescription: 'Access to inbount port(s) on Jenkins Host',
        VpcId: ref('VpcId'),
        SecurityGroupIngress: [
            {
                CidrIp: ref('AccessCidr'),
                IpProtocol: 'tcp',
                FromPort: '8080',
                ToPort: '8080'
            },
            {
                CidrIp: ref('AccessCidr'),
                IpProtocol: 'tcp',
                FromPort: '443',
                ToPort: '443'
            }
        ]
    }

    resource 'InstanceRole', Type: 'AWS::IAM::Role', Properties: {
        AssumeRolePolicyDocument: {
            Statement: [
                {
                    Effect: 'Allow',
                    Principal: {
                        Service: [ 'ec2.amazonaws.com' ]
                    },
                    Action: [ 'sts:AssumeRole']
                }
            ]
        },
        Path: '/'
    }

    resource 'RolePolicies', Type: 'AWS::IAM::Policy', Properties: {
        PolicyName: 'S3Download',
        PolicyDocument: {
            Statement: [
                {
                    Action: [ 's3:ListBucket', 's3:GetBucketLocation', 's3:GetObject', 's3:PutObject' ],
                    Effect: 'Allow',
                    Resource: [ join('', 'arn:aws:s3:::', '/*') ]
                },
                {
                    Action: [
                        'ec2:AttachNetworkInterface',
                        'ec2:DescribeInstances',
                        'ec2:DescribeInstanceStatus',
                        'ec2:DescribeNetworkInterfaces',
                        'ec2:DetachNetworkInterface',
                        'ec2:DescribeNetworkInterfaceAttribute'
                    ],
                    Effect: 'Allow',
                    Resource: '*'
                }
            ]
        },
        Roles: [ ref('InstanceRole') ]
    }

    resource 'BucketProfile', Type: 'AWS::IAM::InstanceProfile', Properties: {
        Path: '/',
        Roles: [ ref('InstanceRole') ]
    }

    resource 'JenkinsServer', Type: 'AWS::EC2::Instance', Properties: {
        IamInstanceProfile: ref('BucketProfile'),
        ImageId: ref('ServerAmi'),
        InstanceType: ref('InstanceType'),
        KeyName: ref('KeyName'),
        NetworkInterfaces: [
            {
                AssociatePublicIpAddress: true,
                DeviceIndex: '0',
                GroupSet: [
                    fn_if('AdminSecCond', ref('AdminSecurity'), ref('AdminSecurityGroup')),
                    fn_if('AccessSecCond', ref('AccessSecurity'), ref('AccessSecurityGroup'))
                ],
                SubnetId: ref('AdminSubnet')
            }
        ],
        UserData: base64(interpolate(file('scripts/userdata.sh')))
    },
    Metadata: {
        'AWS::CloudFormation::Authentication': {
            S3AccessCreds: {
                type: 'S3',
                roleName: ref('InstanceRole')
            }
        },
        'AWS::CloudFormation::Init': {
            configSets: {
                InstallAndRun: [
                    'Install',
                    'Configure'
                ]
            },
            Install: {
                packages: {
                    yum: {}
                },
                files: {
                    '/etc/cfn/cfn-hup.conf': {
                        content: interpolate(file('config/cfn-hup.conf.tpl')),
                        mode: '0644',
                        owner: 'root',
                        group: 'root'
                    },
                    '/etc/cfn/cfn-auto-reloader.conf': {
                        content: interpolate(file('config/cfn-auto-reloader.conf.tpl')),
                        mode: '0644',
                        owner: 'root',
                        group: 'root'
                    }
                },
                services: {
                    sysvinit: { enabled: true, ensurerunning: true },
                    'cfn-hup': { enabled: true, ensurerunning: true, files: [ '/etc/cfn/cfn-hup.conf', '/etc/cfn/hooks.d/cfn-auto-reloader.conf' ] },
                    tomcat8: { enabled: true, ensurerunning: true, files: [ '/etc/tomcat8/tomcat8.conf' ] },
                    'newrelic-sysmond': { enabled: true, ensurerunning: true, files: [ '/etc/newrelic/nrsysmond.cfg' ] } 
                }
            },
            Configure: {
                commands: {
                    '10_start_newrelic': {
                        command: '/etc/init.d/newrelic-sysmond start'
                    },
                    '99_start_tomcat': {
                        command: 'service tomcat8 restart'
                    }
                }
            }
        }
    }

    resource 'DnsEntry', Type: 'AWS::Route53::RecordSet', Properties: {
        HostedZoneName: join('', ref('ZoneName'), '.'),
        Comment: 'Continuous Integration Service',
        Name: join('', 'jenkins', '.', ref('ZoneName'), '.'),
        Type: 'A',
        TTL: '600',
        ResourceRecords: [ get_att('JenkinsServer', 'PublicIp') ]
    }

end.exec!
