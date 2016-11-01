#!/bin/bash
export AWS_DEFAULT_REGION=us-east-1

EC2_REGIONS=$(aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text)

for reg in ${EC2_REGIONS[@]}; do
export AWS_DEFAULT_REGION=$reg

INSTANCES=`aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text`

if [[ -z $INSTANCES ]]; then
echo "no instances in $reg"
else
for ID in $INSTANCES; do

# We could probably use less aws calls...

NAME=`aws ec2 describe-tags --filters "Name=resource-id,Values=$ID" "Name=key,Values=Name" | jq -r .Tags[].Value`
SSHPORT=`aws ec2 describe-tags --filters "Name=resource-id,Values=$ID" "Name=key,Values=SSHPort" | jq -r .Tags[].Value`

VALS=`aws ec2 describe-instances --filters "Name=instance-id,Values=$ID" | jq -r "@csv \"\(.Reservations[].Instances[] | [\"$reg\",\"${NAME}\",\"${SSHPORT}\",.InstanceId,.InstanceType,.PrivateIpAddress,.PublicIpAddress,.KeyName])\""`

INSERTME="INSERT INTO xtnbu.instance(instance_regcode,instance_name, instance_sshport, instance_inid, instance_intype, instance_privip, instance_pubip, instance_keyname) VALUES ($VALS);"
INSERTME=$(echo $INSERTME | tr '"' "'")
INSERTME=$(echo $INSERTME | sed -e 's/,,/,'NULL',/g')
INSERTME=$(echo $INSERTME | sed -e 's/,,/,'NULL',/g')

cat << EOF >> ec2.sql
$INSERTME
EOF

done
fi


done
