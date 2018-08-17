#!/bin/bash
SERVICE_ACCOUNT_FILE="target/eks-admin-service-account.yaml"
CLUSTER_ROLE_FILE="target/eks-admin-cluster-role-binding.yaml"

cat << EOL > $SERVICE_ACCOUNT_FILE
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
EOL
kubectl apply -f $SERVICE_ACCOUNT_FILE

cat << EOL > $CLUSTER_ROLE_FILE
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
EOL
kubectl apply -f $CLUSTER_ROLE_FILE

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

echo "Use the above token to access the dashboard"
echo "Now execute 'kubectl proxy', navigate to http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ and enter the auth token from above"

