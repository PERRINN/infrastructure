[cfn-auto-reloader-hook]
triggers=post.update
path=Resources.JenkinsServer.Metadata.AWS::CloudFormation::Init
action=/opt/aws/bin/cfn-init -v --stack {{ aws_stack_name() }} --resource JenkinsServer --configsets InstallAndRun --region {{ ref('AWS::Region') }}
runas=root

