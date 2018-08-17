#!/bin/bash -x
if [ $# -ne 3 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name> <instance-type>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster t2.medium"
   exit 1
fi

REGION=$1
CLUSTER_NAME=$2
INSTANCE_TYPE=$3

./create-cluster.sh $REGION $CLUSTER_NAME
if [ $? -ne 0 ]
then
  echo "failed to create new cluster - you may need to clean up first"
  exit 1
fi

./create-kube-config.sh $REGION $CLUSTER_NAME
./create-workers.sh $REGION $CLUSTER_NAME $INSTANCE_TYPE
if [ $? -ne 0 ]
then
  echo "failed to create new workers for cluster"
  exit 1
fi
./authorise-names.sh $REGION $CLUSTER_NAME

echo "Creating dashboard"
./create-dashboard.sh

