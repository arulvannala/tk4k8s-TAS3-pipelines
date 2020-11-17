rm -rf gke/
date
echo "##################################################################################"
echo "Creating cluster config and pushing it to S3 storage"
echo "##################################################################################"

#gcloud auth activate-service-account  --key-file /Users/arulvannala/.tf4k8s/gcp/terraform-pa-avannala2-service-account-credentials.json

./config-starter.sh

echo "##################################################################################"
echo "Creating GINI CLUSTER with one node with n1-standard-4 machine in us-west region."
echo "##################################################################################"
gcloud container clusters create gini --num-nodes=1 -m n1-standard-4

echo "##################################################################################"
echo "Getting GINI NODES.. looking good "
echo "##################################################################################"
kubectl get no

echo "##################################################################################"
echo "GINI Install VMware Concourse. "
echo "##################################################################################"
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm install gini concourse/concourse

echo "##################################################################################"
echo "Install Completed "
echo "##################################################################################"

while [[ $(kubectl get pods -l app=gini-web -l release=gini  -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True True True" ]]; do echo "Checking for concourse pod" && sleep 1; done
while [[ $(kubectl get pod gini-postgresql-0 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for postgresql" && sleep 1; done

echo "##################################################################################"
echo "Concouse is up and running.. Ready to FLY .. "
echo "##################################################################################"

kubectl get po

echo "##################################################################################"
echo "Creating Concourse vars as Kubernetes Secets and will be used in our Launch Pod"
echo "##################################################################################"
#path to concouse var files. in this case i am running form tf4k8s-pipeline folder

kubectl create secret generic concourse-create-vars --from-file=gke/ci/$environment_name/gcp/common.yml

echo "##################################################################################"
echo "Getting pods state. Looking good"
echo "##################################################################################"
kubectl get po

echo "##################################################################################"
echo "Lauching TAS3 pipelines via kubernetes pod.... "
echo "##################################################################################"
kubectl apply -f launch-pod.yml

#while [[ $(kubectl get pods -l app=launch-pod  -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True True True" ]]; do echo "Checking for concourse pod" && sleep 1; done
echo "##################################################################################"
echo " Lets check concourse"
echo "##################################################################################"

export POD_NAME=$(kubectl get pods --namespace default -l "app=gini-web" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use Concourse"
kubectl port-forward --namespace default $POD_NAME 8080:8080
