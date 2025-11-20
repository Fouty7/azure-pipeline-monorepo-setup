#This readme is meant to encompass dependency installs that are 1. not yet pipelined and 2 do not require a custom impl. 


#NGINX Ingress Controller

#Step 1: Install the NGINX Ingress Controller
# Add the Nginx Ingress Helm Repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the controller into a dedicated namespace
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

Step 2: Get the ingress Controller's External IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

