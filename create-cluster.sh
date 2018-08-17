#!/bin/bash -x

if [ $# -ne 2 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster"
   exit 1
fi

REGION=$1
CLUSTER_NAME=$2

cluster=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION`
if [ $? -ne 0 ]; then
    echo "No existing cluster with name $CLUSTER_NAME - creating new cluster"
    # extract the subnets, excluding us-east-1b (not enough resources error), as a list of strings (the -r plain texts the output) and join the list with a comma
    SUBNETS=`aws ec2 describe-subnets --region $REGION --query 'Subnets[*].{AZ:AvailabilityZone,Subnet:SubnetId}' | jq -r '.[] | select (.AZ!="us-east-1b") | .Subnet' | paste -sd "," -`
    # get the security group for the security group created for eks
    SECURITY_GROUP_ID=`aws ec2 describe-security-groups --region $REGION --query SecurityGroups | jq -r '.[] | select(.GroupName | startswith("eks-vpc")) | .GroupId'`
    ROLE_ARN=`aws iam list-roles | jq -r '.[][] | select(.RoleName=="eksServiceRole") | .Arn'`

    aws eks create-cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --role-arn $ROLE_ARN \
        --resources-vpc-config subnetIds=$SUBNETS,securityGroupIds=$SECURITY_GROUP_ID
fi

while true
do
    ClusterStatus=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.status`
    if [ $ClusterStatus == "\"CREATING\"" ]
    then
        sleep 10
    elif [ $ClusterStatus == "\"ACTIVE\"" ]
    then
        echo "cluster successfully created"
        exit 0
    else
        echo "cluster creation unsuccessful - $ClusterStatus"
        exit 1
    fi
done
exit 0