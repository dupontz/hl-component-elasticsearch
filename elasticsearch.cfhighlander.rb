CfhighlanderTemplate do

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'Subnets'
    security_groups.each do |name, sg|
      ComponentParam name
    end if defined? security_groups

    ComponentParam 'ESDomainName'
    ComponentParam 'ElasticsearchVersion'
    ComponentParam 'InstanceCount', 1
    ComponentParam 'InstanceType', 't2.micro.elasticsearch'
    ComponentParam 'EncryptionAtRest', 'true', allowedValues: ['true','false']
    ComponentParam 'AutomatedSnapshotStartHour', '0'

  end

end