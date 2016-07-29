#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

template do

	value	:AWSTemplateFormatVersion => '2010-09-09'
	value	:Description => 'Perrinn Full Application Stack'

	#UserData-specific parameters

	#Stack-specific parameters

	parameter 'admin_cidr',
			:AllowedPattern => '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
            :ConstraintDescription => 'must be a valid IP CIDR range of the form x.x.x.x/x.',
            :Description => 'The IP address range that can be used to SSH to the EC2 instances',
            :MaxLength => '18',
            :MinLength => '9',
            :Type => 'String'

    parameter 'bucket_name',
    		:Description => 'Location for locally-managed files',
    		:Type => 'String'

    parameter 'database',
    		:Description => 'Endpoint for pre-existing database service',
    		:Type => 'String'

    parameter 'database_instance_class',
			:AllowedValues => [ 't2.micro', 't2.large', 'm4.large' ],
            :ConstraintDescription => 'must be a valid EC2 instance type.',
            :Default => 'm4.large',
            :Description => 'Server EC2 instance type',
            :Type => 'String'

    parameter 'database_snapshot',
    		:Description => 'snapshot for creating the database service',
    		:Type => 'String'

    parameter 'database_password',
    		:Description => 'Password for the database master user',
    		:Type => 'String',
    		:NoEcho => true

    parameter 'database_storage',
    		:Description => 'Size of the database in GB',
    		:Type => 'String'

    parameter 'database_user',
    		:Description => 'Administrative user',
    		:Type => 'String'

    parameter 'dns_domain_name',
    		:Description => 'Zone to register endpoints'

    parameter 'dns_zone_id',
    		:Description => 'Route53 ID for the dns domain name'

    parameter 'host_name',
    		:Description => 'Host name to register in Route 53',
    		:Type => 'String',
    		:Default => 'api'

    parameter 'key_name',
    		:Description => 'SSH Key for admin access'

    parameter 'db_host_name',
    		:Description => 'Host name to register in Route 53',
    		:Type => 'String',
    		:Default => 'db'

    parameter 'newrelic_license_key',
    		:Description => 'Refer to new relic support docs',
    		:Type => 'String'

    parameter 'server_ami',
    		:AllowedPattern => 'ami-[a-z0-9]{8}',
            :ConstraintDescription => 'must be a valid ami id',
            :Description => 'App Server AMI ID',
            :MaxLength => '12',
            :MinLength => '12',
            :Type => 'String'

    parameter 'server_instance_type',
    		:AllowedValues => [ 't2.micro', 't2.small', 't2.medium', 't2.large'],
    		:Default => 't2.micro',
    		:Type => 'String'

    parameter 'script_region',
			:Type => 'String',
			:Description => 'Region in which to launch the script',
			:AllowedValues => [ 'ap-northeast-1', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2', 'eu-central-1', 'us-east-1', 'us-west-1', 'us-west-2' ],
			:Default => 'ap-southeast-2'

	parameter 'subnets',
			:Type => 'CommaDelimitedList'

	parameter 'vpc_id',
			:AllowedPattern => 'vpc-[a-z0-9]{8}',
            :ConstraintDescription => 'must be a valid vpc id',
            :Description => 'VPC Hosting the service',
            :MaxLength => '12',
            :MinLength => '12',
            :Type => 'String'

	condition 'database_condition',
			equal( ref('database'), "" )

	mapping 'size_map', 'maps/size_map.rb'


	resource 'app_server_security_group', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
		:GroupDescription => 'Server Access Security',
		:VpcId => ref('vpc_id'),
		:SecurityGroupIngress => [
			{
				:CidrIp => ref('admin_cidr'),
				:FromPort => '22',
				:ToPort => '22',
				:Protocol => 'tcp' 
			},
			{
				:SourceSecurityGroupId => ref('web_server_security'),
				:FromPort => '8080',
				:ToPort => '8080',
				:Protocol => 'tcp'
			}
		]
	}

	resource 'web_server_security_group', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
		:GroupDescription => 'Web Access Security',
		:VpcId => ref('vpc_id'),
		:SecurityGroupIngress => [
			{
				:CidrIp => '0.0.0.0/0',
				:FromPort => '80',
				:ToPort => '80',
				:Protocol => 'tcp'
			} 
		]
	}

	resource 'database_security_group', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
		:GroupDescription => 'Data Access Security',
		:VpcId => ref('vpc_id'),
		:SecurityGroupIngress => [
			{
				:CidrIp => ref('admin_cidr'),
				:FromPort => '3306',
				:ToPort => '3306',
				:Protocol => 'tcp' 
			},
			{
				:SourceSecurityGroupId => ref('app_server_security'),
				:FromPort => '3306',
				:ToPort => '3306',
				:Protocol => 'tcp'
			}
		]
	}

	resource 'database_service', :Type => 'AWS::RDS::DBInstance', :Condition => 'database_condition', :Properties => {
		:Engine => 'MySQL',
		:DBName => fn_if( 'db_ss_condition', '', ref('database_snapshot') ),
		:DBInstanceClass => ref('database_instance_class'),
		:MasterUserName => ref('database_user'),
		:MasterUserPassword => ref('database_password'),
		:Port => '3306',
		:PubliclyAccessible => true,
		:MultiAz => false,
		:AllocatedStorage => ref('database_storage'),
		:VPCSecurityGroups => ref('database_security_group')
	}

	resource 'instance_role', :Type => 'AWS::IAM::Role', :Properties => {
		:AssumeRolePolicyDocument => {
			:Statement => [
				{
					:Effect => "allow",
					:Principal => {
						:Service => [
							'ec2.amazonaws.com'
						]
					},
					:Action => [
						'sts:AssumeRole'
					]
				}
			],
			:Path => '/'
		}
	}

	resource 'role_policies', :Type => 'AWS::IAM::Policy', :Properties => {
		:PolicyName => 's3download',
		:PolicyDocument => {
			:Statement => [
				{
					:Action => [
						's3:ListBucket',
						's3:GetBucketLocation',
						's3:GetObject'
					],
					:Effect => 'Allow',
					:Resource => [
						join('', 'arn:aws:s3:::', ref('bucket_name'), '/*')
					]
				}
			]
		},
		:PolicyDocument => [
			ref('instance_role')
		]
	}

	resource 'bucket_profile', :Type => 'AWS::IAM::InstanceProfile', :Properties => {
		:Path => '/',
		:Roles => [
			ref('instance_role')
		]
	}

	resource 'load_balancer', :Type => '', :Properties => {
		:Scheme => 'AWS::ElasticLoadBalancing::LoadBalancer',
		:Subnets => ref('subnets'),
		:Listeners => [
			{
				:LoadBalancerPort => '80',
				:InstancePort => '8080',
				:Protocol => 'HTTP'
			}
		],
		:HealthCheck => {
			:HealthyThreshold => '3',
			:Interval => '30',
			:Target => 'TCP:8080',
			:Timeout => '5',
			:UnhealthyThreshold => '5'
		},
		:SecurityGroups => [
			ref('web_server_security_group')
		],
		:CrossZone => true
	}

	resource 'database_route53', :Type => 'AWS::Route53::RecordSet', :Properties => {
		:HostedZoneId => ref('dns_zone_id'),
		:Name => join('.', ref('db_host_name'), ref('dns_domain_name')),
		:Type => 'CNAME',
		:TTL => '900',
		:ResourceRecords => [
			get_att('database_service', 'Endpoint.Address')
		]
	}

	resource 'elb_route53', :Type => 'AWS::Route53::RecordSetGroup', :Properties => {
		:HostedZoneName => join('', ref('dns_domain_name'), '.'),
		:Comment => 'Target Front-End ELB',
		:RecordSets => [
			:Name => join('.', ref('host_name'), ref('dns_domain_name')),
			:Type => 'A',
			:AliasTarget => {
				:HostedZoneId => get_att('load_balancer', 'CanonicalHostedZoneNameID'),
				:DNSName => get_att('load_balancer', 'CanonicalHostedZoneName')
			}
		]
	}

	resource 'app_server_launch_config', :Type => 'AWS::AutoScaling::LaunchConfiguration', :Properties => {
		:AssociatePublicIpAddress => true,
		:ImageId => ref('server_ami'),
		:InstanceType => ref('server_instance_type'),
		:InstanceMonitoring => false,
		:KeyName => ref('key_name'),
		:IamInstanceProfile => ref('bucket_profile'),
		:SecurityGroups => [
			ref('app_server_security')
		],
		:UserData => base64(interpolate(file('scripts/instance-bootstrap.sh'), time: Time.now))
	},
	:Metadata => {
		:'AWS::CloudFormation::Authentication' => {
			:S3AccessCreds => {
				:type => 'S3',
				:roleName => ref('instance_role'),
				:buckets => [
					ref('bucket_name')
				]
			}
		},
		:'AWS::CloudFormation::Init' => {
			:configSets => {
				:InstallAndRun => [ 'Install', 'Configure' ]
			},
			:Install => {
				:packages => {
					:yum => {
						:'newrelic-sysmond' => [],
						:'rsyslog' => []
					}
				},
				:files => {
					:'/etc/rsyslog.d/22-loggly.conf' => {
						:Content => file('scripts/22-loggly.conf'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'
					},
					:'/etc/rsyslog.d/21-tomcat.conf' => {
						:Content => file('scripts/21-tomcat.conf'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'
					},
					:'/etc/tomcat8/tomcat-users.xml' => {
						:Content => file('scripts/tomcat-users.xml'),
						:mode => '000644',
						:owner => 'tomcat',
						:group => 'tomcat'
					},
					:'/etc/tomcat8/tomcat8.conf' => {
						:Content => file('scripts/tomcat8.conf'),
						:mode => '000644',
						:owner => 'tomcat',
						:group => 'tomcat'
					},
					:'/etc/cfn/cfn-hup.conf' => {
						:Content => file('scripts/cfn_hup.conf'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'
					},
					:'/etc/cfn/hooks.d/cfn-auto-reloader.conf' => {
						:Content => file('scripts/cfn_auto_reloader.conf'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'
					},
					:'/tmp/newrelic-platform.zip' => {
						:Source => join('','https://s3-',ref('AWS::Region'),'.amazonaws.com/',ref('bucket_name'),'/bin/newrelic-platform.zip'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'	
					},
					:'/tmp/platform.war' => {
						:Source => join('','https://s3-',ref('AWS::Region'),'.amazonaws.com/',ref('bucket_name'),'/bin/platform.war'),
						:mode => '000644',
						:owner => 'root',
						:group => 'root'	
					}
				},
				:services => {
					:sysvinit => {
						:enabled => true,
						:ensurerunning => true
					},
					:tomcat8 => {
						:enabled => true,
						:ensurerunning => true
					},
					:'newrelic-sysmond' => {
						:enabled => true,
						:ensurerunning => true
					},
					:rsyslog => {
						:enabled => true,
						:ensurerunning => true
					},
					:'cfn-hup' => {
						:enabled => true,
						:ensurerunning => true,
						:files => [
							'/etc/cfn/cfn-hup.conf',
							'/etc/cfn/hooks.d/cfn-auto-reloader.conf'
						]
					}
				}
			},
			:Configure => {
				:commands => {
					:'01_prestart_rsyslog' =>{
						:command => 'chkconfig rsyslog on'
					},
					:'02_start_rsyslog' => {
						:command => 'service rsyslog restart'
					},
					:'03_configure_newrelic' => {
						:command => join('', 'nrsysmond-config --set license_key=', ref('newrelic_license_key'))
					},
					:'04_newrelic_agent' => {
						:command => 'unzip /tmp/newrelic-afant.zip -d /usr/share/tomcat8'
					},
					:'05_prestart_newrelic' => {
						:command => 'chkconfig newrelic-sysmond on'
					},
					:'06_start_newrelic' => {
						:command => '/etc/init.d/newrelic-sysmond start'
					},
					:'80_unpack_app' => {
						:command => 'mv /tmp/platform.war /usr/share/tomcat8/webapps'
					},
					:'81_load_config_1' => {
						:command => 'service tomcat8 start; sleep 60; service tomcat8 stop'
					},
					:'90_prestart_tomcat' => {
						:command => 'chkconfig tomcat8 on'
					},
					:'99_start_tomcat' => {
						:command => 'service tomcat8 start'
					}
				}
			}
		}
	}

	resource 'autoscaling_group', :Type =>'AWS::AutoScaling::AutoScalingGroup', :Properties => {
		:AvailabilityZones => get_azs(ref('AWS::Region')),
		:CoolDown => '600',
		:DesiredCapacity => '1',
		:LaunchConfigurationName => ref('app_server_launch_config'),
		:MaxSize => '2',
		:MinSize => '1',
		:TerminationPolicies => [ 'OldestInstance', 'ClosestToNextInstanceHour'],
		:VPCZoneIdentifier => ref('subnets'),
		:LoadBalancerNames => ref('load_balancer'),
		:Tags => [	
			{
				:Key => 'Name',
				:Value => 'perrinn-app',
				:PropagateAtLaunch => true
			}
		]
	}

	resource 'scale_up_policy', :Type => 'AWS::AutoScaling::ScalingPolicy', :Properties => {
		:AdjustmentType => 'ChangeInCapacity',
		:AutoScalingGroupName => ref('AutoScalingGroup'),
		:Cooldown => '1',
		:ScalingAdjustment => '1'
	}

	resource 'scale_down_policy', :Type => 'AWS::AutoScaling::ScalingPolicy', :Properties => {
		:AdjustmentType => 'ChangeInCapacity',
		:AutoScalingGroupName => ref('AutoScalingGroup'),
		:Cooldown => '1',
		:ScalingAdjustment => '-1'
	}

	resource 'CPUHighAlarm', :Type => 'AWS::CloudWatch::Alarm', :Properties => {
		:EvaluationPeriods => '1',
		:Statistic => 'Average',
		:Threshold => '80',
		:AlarmDescription => 'Alarm if CPU too high or metric disappears indicating instance is down',
		:Period => '60',
		:AlarmAction => ref('scale_up_policy'),
		:NameSpace => 'AWS/EC2',
		:Dimensions => [
			{
				:Name => 'AutoScalingGroupName',
				:Value => ref('autoscaling_group')
			}
		],
		:ComparisonOperator => 'GreaterThanThreshold',
		:MetricName => 'CPUUtilization'
	}

	resource 'CPULowAlarm', :Type => 'AWS::CloudWatch::Alarm', :Properties => {
		:EvaluationPeriods => '2',
		:Statistic => 'Average',
		:Threshold => '50',
		:AlarmDescription => 'Alarm if CPU too low or metric disappears indicating instance is down',
		:Period => '60',
		:AlarmAction => ref('scale_down_policy'),
		:NameSpace => 'AWS/EC2',
		:Dimensions => [
			{
				:Name => 'AutoScalingGroupName',
				:Value => ref('autoscaling_group')
			}
		],
		:ComparisonOperator => 'LessThanThreshold',
		:MetricName => 'CPUUtilization'
	}

end.exec!
