[cfn-auto-reloader-hook]
triggers=post.update
path=Resources.JenkinsLaunchConfig.Metadata.AWS::CloudFormation::Init
action=/opt/aws/bin/cfn-init -v --stack {{ aws_stack_name() }} --resource JenkinsLaunchConfig --configsets InstallAndRun --region {{ ref('AWS::Region') }}
runas=root

