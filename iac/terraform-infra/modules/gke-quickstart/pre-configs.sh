NODE_POOL=$(terraform output | grep node_pool_name | awk '{print $3}')
CLUSTER_NAME=$(terraform output | grep kubernetes_cluster_name | awk '{print $3}')

#gcloud container node-pools update $NODE_POOL --workload-metadata=GKE_METADATA --location-policy=BALANCED --cluster=$CLUSTER_NAMEA

gcloud container clusters update react-blog-c29c7-gke \
--project=react-blog-c29c7 \
--region=us-central1 \
--workload-pool=react-blog-c29c7.svc.id.goog