#!/bin/bash -x
CLUSTER_NAME="eks-cluster"
REGION="us-east-1"

STACK_NAME="$CLUSTER_NAME-vpc"
echo "Creating VPC"

aws cloudformation create-stack \
   --stack-name $STACK_NAME \
   --region $REGION \
   --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/amazon-eks-vpc-sample.yaml 

while true
do
   StackStatus=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query Stacks[*].StackStatus | jq -r .[]`
   if [ "$StackStatus" == "CREATE_IN_PROGESS" ]
   then
       echo "."
       sleep 10
   elif [ "$StackStatus" == "CREATE_COMPLETE" ]
   then
       echo "VPC Stack successfully created"
       exit 0
   else
       echo "Stack creation unsuccessful - $StackStatus"
       exit 1
   fi
done