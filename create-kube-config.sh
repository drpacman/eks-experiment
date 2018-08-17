#!/bin/bash -x
if [ $# -ne 2 ] 
then
   echo "Usage" `basename $0` "<region> <cluster-name>"
   echo "e.g." `basename $0` "us-east-1 eks-cluster"
   exit 1
fi
REGION=$1
CLUSTER_NAME=$2


KUBE_CONFIG_FILE="$HOME/.kube/config-$CLUSTER_NAME"
ENDPOINT=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.endpoint`
CERT_AUTH_DATA=`aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query cluster.certificateAuthority.data`

cat << EOF > $KUBE_CONFIG_FILE
apiVersion: v1
clusters:
- cluster:
    server: $ENDPOINT
    certificate-authority-data: $CERT_AUTH_DATA
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "$CLUSTER_NAME"
        # - "-r"
        # - "<role-arn>"
      # env:
        # - name: AWS_PROFILE
        #   value: "<aws-profile>"
EOF
echo "Create kube congfig in $KUBE_CONFIG_FILE"
RETVAL=`grep $KUBE_CONFIG_FILE ~/.bash_profile`
if [ $? -ne 0 ]; then
   echo "Adding to bash profile"
   echo "export KUBECONFIG=$KUBECONFIG:$KUBE_CONFIG_FILE" >> ~/.bash_profile
fi
export KUBECONFIG=$KUBE_CONFIG_FILE
echo "Checking can access cluster"
kubectl get svc