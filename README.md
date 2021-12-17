# elasticsearch CfHighlander component

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| AvailabilityZones | Number of AZs to deploy to | 1 | true | int | [1,2,3]
| VPCId | Id of the vpc required for creating a target group and security group | - | false | AWS::EC2::VPC::Id
| SubnetIds | list of subnet ids to run your tasks in if using aws-vpc networking | - | false | comma delimited string
| ESDomainName | Domain name to be used for the cluster | None | false | string
| ElasticsearchVersion | The version of ES to deploy | None | false | string
| InstanceCount | The number of instances to deploy | 1 | false | int
| InstanceType | The instance type to deploy | t2.micro.elasticsearch | false | string
| EncryptionAtRest | Whether or not to use Encryption at Rest | true | false | string | ['true','false']
| AutomatedSnapshotStartHour | The hour of the day *in UTC* to snapshot the cluster | 0 | false | string
| DedicatedMasterCount | The number of master noodes in the cluster | None | false | string
| DedicatedMasterType | The instance type for the master nodes | None | false | string

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| ESClusterEndpoint | The domain endpoint of the created cluster | true
| SecurityGroupES | The security group of the created cluster | true

## Included Components

[lib-ec2](https://github.com/theonestack/hl-component-lib-ec2)
## Example Configuration
### Highlander
```
  Component template: 'elasticsearch', name: 'es' do
    parameter name: 'ESDomainName', value: FnSub("${EnvironmentName}-es")
    parameter name: 'ElasticsearchVersion', value: '6.5'
    parameter name: 'InstanceCount', value: '1'
    parameter name: 'InstanceType', value: 't2.small.elasticsearch'
    parameter name: 'Subnets', value: cfout('vpc.CacheSubnets')
    parameter name: 'EncryptionAtRest', value: 'true'
  end 

```

### Elasticsearch Configuration
```
ebs_options:
  EBSEnabled: true
  VolumeSize: 20
  VolumeType: gp2
security_groups:
  SecurityGroupBastion:
    ports:
      - from: 22
        to: 22
      - from: 443
        to: 443
      - from: 9200
        to: 9200
  SecurityGroupBackplane:
    ports:
      - from: 22
        to: 22
      - from: 443
        to: 443
```

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```
## Testing Components

Running the tests

```bash
cfhighlander cftest elasticsearch
```