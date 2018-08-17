#!/bin/bash -x
if [ $# -ne 2 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster"
   exit 1
fi

REGION=$1
CLUSTER_NAME=$2

AUTHFILE="target/aws-auth-cm-$CLUSTER_NAME.yaml"
STACK_NAME="$CLUSTER_NAME-eks-workers"

roleArn=`aws cloudformation describe-stacks --region $REGION --stack-name $STACK_NAME --query Stacks[*].Outputs[*] | jq -r '.[][] | select(.OutputKey=="NodeInstanceRole") | .OutputValue'`
cat << EOL > $AUTHFILE
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $roleArn
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOL

KUBECONFIG="$HOME/.kube/config-$CLUSTER_NAME"
kubectl apply -f $AUTHFILE
kubectl get nodes --watch