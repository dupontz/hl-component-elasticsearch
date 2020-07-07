
CloudFormation do

  safe_component_name = external_parameters[:component_name].capitalize.gsub('_','').gsub('-','')

  Condition("ZoneAwarenessEnabled", FnNot(FnEquals(Ref(:AvailabilityZones), 1)))
  Condition("Az2", FnEquals(Ref(:AvailabilityZones), 2))
  Condition("Az3", FnEquals(Ref(:AvailabilityZones), 3))

  sg_tags = []
  sg_tags << { Key: 'Environment', Value: Ref(:EnvironmentName)}
  sg_tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType)}
  sg_tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")}

  extra_tags = external_parameters.fetch(extra_tags, {})
  extra_tags.each { |key,value| sg_tags << { Key: "#{key}", Value: FnSub(value) } }

  EC2_SecurityGroup("SecurityGroupES") do
    GroupDescription FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")
    VpcId Ref('VPCId')
    Tags sg_tags
  end

  security_groups = external_parameters.fetch(:security_groups, {})
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
  end

  advanced_options = external_parameters.fetch(:advanced_options, {})
  ebs_options = external_parameters.fetch(:ebs_options, {})

  subnets = FnIf('Az2',
                [
                  FnSelect(0, FnSplit(',', Ref('Subnets'))), 
                  FnSelect(1, FnSplit(',', Ref('Subnets')))
                ],
                FnIf('Az3',
                  [
                    FnSelect(0, FnSplit(',', Ref('Subnets'))), 
                    FnSelect(1, FnSplit(',', Ref('Subnets'))), 
                    FnSelect(2, FnSplit(',', Ref('Subnets')))
                  ],
                  [
                    FnSelect(0, FnSplit(',', Ref('Subnets')))
                  ]
                )
              )

  Elasticsearch_Domain('ElasticSearchVPCCluster') do
    DomainName Ref('ESDomainName')
    AdvancedOptions advanced_options unless advanced_options.empty?
    EBSOptions ebs_options unless ebs_options.empty?
    ElasticsearchClusterConfig({
      InstanceCount: Ref('InstanceCount'),
      InstanceType: Ref('InstanceType'),
      ZoneAwarenessEnabled: FnIf('ZoneAwarenessEnabled', 'true','false'),
      ZoneAwarenessConfig: {
        AvailabilityZoneCount: Ref(:AvailabilityZones)
      }
    })
    ElasticsearchVersion Ref('ElasticsearchVersion')
    EncryptionAtRestOptions({
      Enabled: Ref('EncryptionAtRest')
    })
    SnapshotOptions({
      AutomatedSnapshotStartHour: Ref('AutomatedSnapshotStartHour')
    })
    VPCOptions({
      SubnetIds: subnets,
      SecurityGroupIds: [Ref('SecurityGroupES')]
    })
    Tags sg_tags
    AccessPolicies(
      {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Principal: {
            AWS: "*"
          },
          Action: "es:*",
          Resource: FnSub("arn:aws:es:${AWS::Region}:${AWS::AccountId}:domain/${ESDomainName}/*")
        }]
      }
    )
  end

  Output("ESClusterEndpoint") do
    Value(FnGetAtt('ElasticSearchVPCCluster', 'DomainEndpoint'))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-ESClusterEndpoint")
  end

  Output("SecurityGroupES") do
    Value(Ref('SecurityGroupES'))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-SecurityGroup")
  end

end