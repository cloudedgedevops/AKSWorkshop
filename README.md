# AKSWorkshop

  1. Create a Resource Group for the workshop

## Deploy Azure Kubernetes Service

   1. Navigate to **Kubernetes services** and hit **create**.

   2. Choose your subscription and Resource Group you just created.

   3. **Cluster preset Configuration** - Dev/Test
    
   4. **Kubernetes cluster name** - aksworkshop

   5. **Region** - West Europe

   6. **Availability zones** - None

   7. **Node Size** - Change size to B2s

   8. **Scale method** - Autoscale - min 1 Max 2

   9. Click **review + create** 
   
   11. az aks update -g RESOURCEGROUPNAME -n aksworkshop --enable-managed-identity
    
    
## Deploy a Container Registry (ACR)

   1. Navigate to **Container registries** and hit create.

   2. Choose your subscription and Resource Group.

   3. Enter a **uniqe name** for the container registry.

   4. **SKU** - Basic.

   5. Click **Review + create**
   
   6. az aks update -n aksworkshop -g YOURRESOURCEGROUP --attach-acr YOURACRNAME
 
 
## Deploy an Application Gateway V2

  1. az network public-ip create -n PublicIPName -g YOURRESOURCEGROUP --allocation-method Static --sku Standard -l westeurope

  2. az network vnet subnet create -n agic --vnet-name AKSVNETNAME -g YOURRESOURCEGROUP --address-prefixes 10.242.0.0/16 (example, choose according you aks vnet adress space)

  3. az network application-gateway create -n APPGWNAME -l westeurope -g YOURRESOURCEGROUP --sku Standard_v2 --public-ip-address PublicIPName --vnet-name AKSVNETNAME --subnet agic --priority 100


## Build and push the containers images

  1. Open **Cloud Shell** on the Azure Portal.

  2. Clone this repository - **git clone https://github.com/cloudedgedevops/AKSWorkshop.git**
  
  3. run Docker build -t YOURREGISTRYNAME.azurecr.io/aspnetapp:1.0
  
  4. run az acr login -n YOURREGISTRYNAME
  
  4. run docker push YOURREGISTRYNAME.azurecr.io/aspnetapp:1.0
  
 
  ### Bonus - run the image as non root
  
  1. Edit the dockerfile to run the container as non root user.


## Install Application Gateway Ingress Controller

  1. appgwId=$(az network application-gateway show -n APPGWNAME -g YOURRESOURCEGROUP -o tsv --query "id") 

  2. az aks enable-addons -n myCluster -g myResourceGroup -a ingress-appgw --appgw-id $appgwId

 
 
## Deploy the application to the AKS cluster

1. Run the command az aks get-credentials --resource-group YOURRESOURCEGROUP --name aksworkshop

3. Edit the aspnetapp.yaml to use the images you pushed to the ACR.

3. Run kubectl apply -f aspnetapp.yaml

4. Run kubectl get ing - copy the external IP

5. Browse to - http://YOURINGRESSIP:80
