#!/bin/bash -x
# assumes us-east-1...
NodeImageId="ami-0fef2bff3c2e2da93"
# assumes fixed key pair name
KeyName="eks-key-pair"

if [ $# -ne 3 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name> <instance-type>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster t2.medium"
   exit 1
fi

REGION=$1
CLUSTER_NAME=$2
INSTANCE_TYPE=$3

NODE_GROUP_NAME="node-group-$CLUSTER_NAME"
STACK_NAME="${CLUSTER_NAME}-eks-workers"
StackStatus="Unknown"

check_stack() {
    StackStatus=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query Stacks[*].StackStatus | jq -r .[]`
}

ClusterControlPlaneSecurityGroup=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.resourcesVpcConfig.securityGroupIds | jq -r '.[]'`
Subnets=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.resourcesVpcConfig.subnetIds | jq -r '.[]' | paste -sd "\\," -`
VpcId=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.resourcesVpcConfig.vpcId | jq -r '.'`
    
check_stack
if [[ $StackStatus == ROLLBACK* ]]
then
   echo "Stack already exists and is in rollback state - deleting"
   aws cloudformation delete-stack --region $REGION --stack-name $STACK_NAME
   echo "Sleeping whilst stack deletes..."
   sleep 10
elif [[ $StackStatus == "CREATE_COMPLETE" ]]
then
    echo "Stack already exists"
    exit 0
fi

echo "Creating new stack $STACK_NAME"
aws cloudformation create-stack \
   --stack-name $STACK_NAME \
   --region $REGION \
   --capabilities CAPABILITY_IAM \
   --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/amazon-eks-nodegroup.yaml \
   --parameters ParameterKey=NodeImageId,ParameterValue=$NodeImageId \
                ParameterKey=KeyName,ParameterValue=$KeyName \
                ParameterKey=Subnets,ParameterValue=\"$Subnets\" \
                ParameterKey=VpcId,ParameterValue=$VpcId \
                ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$ClusterControlPlaneSecurityGroup \
                ParameterKey=NodeInstanceType,ParameterValue=$INSTANCE_TYPE \
                ParameterKey=ClusterName,ParameterValue=$CLUSTER_NAME \
                ParameterKey=NodeGroupName,ParameterValue=$NODE_GROUP_NAME
                
while true
do
   check_stack
   if [ "$StackStatus" == "CREATE_IN_PROGESS" ]
   then
       sleep 10
   elif [ "$StackStatus" == "CREATE_COMPLETE" ]
   then
       echo "Stack successfully created"
       exit 0
   else
       echo "Stack creation unsuccessful - $StackStatus"
       exit 1
   fi
done