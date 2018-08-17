#!/bin/bash -x
if [ $# -ne 2 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster"
   exit 1
fi

REGION=$1
CLUSTER_NAME=$2

aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
sleep 5
done=0
while [ $done -eq 0 ]
do
    ClusterStatus=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.status`
    RETVAL=$?
    if [ $RETVAL -eq  0 ]
    then
        if [ $ClusterStatus == "\"DELETING\"" ]
        then
            sleep 10
        elif [ $ClusterStatus == "\"ACTIVE\"" ]
        then
            echo "cluster still active!"
            exit 1
        fi
    else 
       echo "Cluster appears to no longer exist - deletion successful"
       done=1
    fi
done

aws cloudformation delete-stack --region $REGION --stack-name ${CLUSTER_NAME}-eks-workers
while true
do
   StackStatus=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query Stacks[*].StackStatus | jq -r .[]`
   if [ "$StackStatus" == "DELETE_IN_PROGESS" ]
   then
       sleep 10
   elif [ "$StackStatus" == "DELETE_COMPLETE" ]
   then
       echo "Stack successfully deleted"
       exit 0
   else
       echo "Stack deletion unsuccessful - $StackStatus"
       exit 1
   fi
done
