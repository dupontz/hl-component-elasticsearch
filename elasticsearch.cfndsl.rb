
CloudFormation do

  safe_component_name = component_name.capitalize.gsub('_','').gsub('-','')

  Condition("ZoneAwarenessEnabled", FnNot(FnEquals(Ref('InstanceCount'), '1')))

  sg_tags = []
  sg_tags << { Key: 'Environment', Value: Ref(:EnvironmentName)}
  sg_tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType)}
  sg_tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{component_name}")}

  extra_tags.each { |key,value| sg_tags << { Key: "#{key}", Value: FnSub(value) } } if defined? extra_tags

  EC2_SecurityGroup("SecurityGroupES") do
    GroupDescription FnSub("${EnvironmentName}-#{component_name}")
    VpcId Ref('VPCId')
    Tags sg_tags
  end

  security_groups.each do |name, sg|
    sg['ports'].each do |port|
      EC2_SecurityGroupIngress("#{name}SGRule#{port['from']}") do
        Description FnSub("Allows #{port['from']} from #{name}")
        IpProtocol 'tcp'
        FromPort port['from']
        ToPort port.key?('to') ? port['to'] : port['from']
        GroupId FnGetAtt("SecurityGroupES",'GroupId')
        SourceSecurityGroupId sg.key?('stack_param') ? Ref(sg['stack_param']) : Ref(name)
      end
    end if sg.key?('ports')
  end if defined? security_groups


  Elasticsearch_Domain('ElasticSearchVPCCluster') do
    DomainName Ref('ESDomainName')
    AdvancedOptions advanced_options if defined? advanced_options
    EBSOptions ebs_options if defined? ebs_options
    ElasticsearchClusterConfig({
      InstanceCount: Ref('InstanceCount'),
      InstanceType: Ref('InstanceType'),
      ZoneAwarenessEnabled: FnIf('ZoneAwarenessEnabled', 'true','false')
    })
    ElasticsearchVersion Ref('ElasticsearchVersion')
    EncryptionAtRestOptions({
      Enabled: Ref('EncryptionAtRest')
    })
    SnapshotOptions({
      AutomatedSnapshotStartHour: Ref('AutomatedSnapshotStartHour')
    })
    VPCOptions({
      SubnetIds: [FnSelect(0, FnSplit(',', Ref('Subnets')))],
      SecurityGroupIds: [Ref('SecurityGroupES')]
    })
    Tags sg_tags
  end

end