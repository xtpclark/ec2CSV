#!/bin/bash

# EC2_REGIONS=("us-east-1" "us-west-1" "us-west-2" "eu-west-1" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "sa-east-1")

EC2_REGIONS=("us-east-1" "us-west-1" "us-west-2")

for reg in ${EC2_REGIONS[@]}; do
export AWS_DEFAULT_REGION=$reg

INSTANCES=`aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text`

for ID in $INSTANCES; do

NAME=`aws ec2 describe-tags --filters "Name=resource-id,Values=$ID" "Name=key,Values=Name" | jq -r .Tags[].Value`
SSHPORT=`aws ec2 describe-tags --filters "Name=resource-id,Values=$ID" "Name=key,Values=SSHPort" | jq -r .Tags[].Value`

    # aws ec2 describe-instances --filters "Name=instance-id,Values=$ID" | jq -r "@csv \"$reg,${NAME},${SSHPORT},\(.Reservations[].Instances[] | [.InstanceId, .State.Name,.InstanceType,.PrivateIpAddress,.PublicIpAddress,.KeyName]) \""
VALS=`aws ec2 describe-instances --filters "Name=instance-id,Values=$ID" | jq -r "@csv \"\(.Reservations[].Instances[] | [\"$reg\",\"${NAME}\",\"${SSHPORT}\",.InstanceId,.InstanceType,.PrivateIpAddress,.PublicIpAddress,.KeyName])\""`

INSERTME="INSERT INTO xtnbu.instance(instance_regcode,instance_name, instance_sshport, instance_inid, instance_intype, instance_privip, instance_pubip, instance_keyname) VALUES ($VALS);"
INSERTME=$(echo $INSERTME | tr '"' "'")
INSERTME=$(echo $INSERTME | sed -e 's/,,/,'NULL',/g')
INSERTME=$(echo $INSERTME | sed -e 's/,,/,'NULL',/g')

echo $INSERTME
done



done
