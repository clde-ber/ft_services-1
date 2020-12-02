#!/bin/sh

GREEN='\033[0;32m'
BLUE='\033[0;34m'

#sudo usermod -aG docker $USER
#newgrp docker
#sudo chmod 777 /var/run/docker.sock

if [ ! -f kind ]; then
  echo "${GREEN}Installing Kind${END}"
  GO111MODULE="on" go get sigs.k8s.io/kind@v0.9.0
  mv /home/$USER/go .
  mv go/kind .
  rm -rf go
else
  echo "${GREEN}Kind already installed${END}"
fi

./kind delete cluster
./kind create cluster


# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

#>>>>>Deploiement du Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml
#>>>>>Création d'un user pour le dashboard
kubectl apply -f dashboard-admin.yaml
#>>>>>cette commande sert à obtenir un jeton de connexion pour le dashboard
#kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount admin-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

#>>>>>Installation de MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" # On first install only

#>>>>>ConfigMap
kubectl create -f ./srcs/metallb/metallb.yaml


#>>>>> 172.18.0.1
docker build -t img_nginx ./srcs/nginx > /dev/null 2>&1
./kind load docker-image img_nginx
kubectl apply -f ./srcs/nginx/nginx.yaml

#>>>>> 172.18.0.2
docker build -t img_ftps ./srcs/ftps > /dev/null 2>&1
./kind load docker-image img_ftps
kubectl apply -f ./srcs/ftps/ftps.yaml





#>>>>>cette commande pour aovir des infos sur l'ip des services
#kubectl get svc nginx

#>>>>>pour activer le dashboard
#kubectl proxy
#>>>>>http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

