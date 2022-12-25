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
    
    
## Deploy a Container Registry (ACR)

   1. Navigate to **Container registries** and hit create.

   2. Choose your subscription and Resource Group.

   3. Enter a **uniqe name** for the container registry.

   4. **SKU** - Basic.

   5. Click **Review + create**
 
 
## Deploy an Application Gateway V2

  1. az aks update -n aksworkshop -a ingress-appgw --appgw-name myApplicationGateway --appgw-subnet-cidr "Your new subnet CIDR"

  1. Navigate to **Application Gateways** and hit **Create**.

  2. Choose your subscription and Resource Group.

  3. **Application gateway name** - appgwworkshop

  4. **Region** - West Europe

  5. **Tier** - WAF V2

  6. **Enable autoscaling** - No

  7. **Instance count** - 1

  8. **WAF Policy** - Create new

  9. **Vritual network** - **choose the virtual network of the kubernetes nodes**

  9.1 **Hit Manage subnet configuration** - add a new subnet called "appgw", navigate back to the creation and choose the "appgw" subnet.
  
  10. Click Next and **add new public IP address**

  11. **Add a new backend pool** - enter a name and **choose Yes for "Add backend pool without targets"**

  12. 


## Build and push the containers images

  1. Open **Cloud Shell** on the Azure Portal.

  2. Clone this repository - **git clone https://github.com/cloudedgedevops/AKSWorkshop.git**
  
  3. run Docker build -t <YOURREGISTRYNAME>.azurecr.io/aspnetapp:1.0
  
  4. run az acr login -n <YOURREGISTRYNAME>
  
  4. run docker push <YOURREGISTRYNAME>.azurecr.io/aspnetapp:1.0
  
  #Bonus - run the image as non root
  
  1. Edit the dockerfile to run as non root.


## Install Application Gateway Ingress Controller


### Set up AAD Pod Identity

[AAD Pod Identity](https://github.com/Azure/aad-pod-identity) is a controller, similar to AGIC, which also runs on your
AKS. It binds Azure Active Directory identities to your Kubernetes pods. Identity is required for an application in a
Kubernetes pod to be able to communicate with other Azure components. In the particular case here we need authorization
for the AGIC pod to make HTTP requests to [ARM](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview).

To install AAD Pod Identity to your cluster:

   - *RBAC enabled* AKS cluster

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.6.0/deploy/infra/deployment-rbac.yaml
  ```

   - *RBAC disabled* AKS cluster

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.6.0/deploy/infra/deployment.yaml
  ```

Next we need to create an Azure identity and give it permissions to ARM. This identity will be used by AGIC to perform updates on the Application Gateway.
Use [Cloud Shell](https://shell.azure.com/) to run all of the following commands and create an identity:

1. Create a User assigned identity. This identity can be created in any resource group as long as permissions are set correctly. In following steps, we will create the identity in the same resource group as the AKS cluster.

    ```bash
    identityName="<identity-name>"
    resourceGroup="<resource-group>"
    az identity create -g $resourceGroup -n $identityName
    ```

1. For the role assignment commands below we need to obtain `identityId` and `clientId` for the newly created identity:

    ```bash
    identityClientId=$(az identity show -g $resourceGroup -n $identityName -o tsv --query "clientId")
    identityId=$(az identity show -g $resourceGroup -n $identityName -o tsv --query "id")
    ```

1. Give AGIC's identity `Contributor` access to you App Gateway. For this you need the ID of the App Gateway, which will
look something like this: `/subscriptions/A/resourceGroups/B/providers/Microsoft.Network/applicationGateways/C`

    Get the list of App Gateway IDs in your subscription with: `az network application-gateway list --query '[].id'`

    ```bash
    az role assignment create \
        --role "Contributor" \
        --assignee $identityClientId \
        --scope <App-Gateway-ID>
    ```

1. Give AGIC's identity `Reader` access to the App Gateway resource group. The resource group ID would look like:
`/subscriptions/A/resourceGroups/B`. You can get all resource groups with: `az group list --query '[].id'`

    ```bash
    az role assignment create \
        --role "Reader" \
        --assignee $identityClientId \
        --scope <App-Gateway-Resource-Group-ID>
    ```

**Note**: There are additional role assignment required if you wish to assign user-assigned identities that are **NOT** within AKS cluster resource group. You can run the following command to assign the `Managed Identity Operator` role with the identity resource Id.

  ```bash
  aksName="<aks-cluster-name>"
  clusterClientId=$(az aks show -g $resourceGroup -n $aksName -o tsv --query "servicePrincipalProfile.clientId")

  az role assignment create \
    --role "Managed Identity Operator" \
    --assignee $clusterClientId \
    --scope $identityId
  ```

## Install Ingress Controller as a Helm Chart
You can use [Cloud Shell](https://shell.azure.com/) to install the AGIC Helm package:

1. Add the `application-gateway-kubernetes-ingress` helm repo and perform a helm update

    ```bash
    helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
    helm repo update
    ```

1. Download [helm-config.yaml](../examples/sample-helm-config.yaml), which will configure AGIC:
    ```bash
    wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml
    ```

1. Edit [helm-config.yaml](../examples/sample-helm-config.yaml) and fill in the values for `appgw` and `armAuth`.
    ```bash
    nano helm-config.yaml
    ```

    **NOTE:** The `<identityResourceId>` and `<identityClientId>` are the properties of the Azure AD Identity you setup in the previous section. You can retrieve this information by running the following command: `az identity show -g <resourcegroup> -n <identity-name>`, where `<resourcegroup>` is the resource group in which the top level AKS cluster object, Application Gateway and Managed Identify are deployed.

1. Install Helm chart `application-gateway-kubernetes-ingress` with the `helm-config.yaml` configuration from the previous step

    ```bash
    helm install ingress-azure \
      -f helm-config.yaml \
      application-gateway-kubernetes-ingress/ingress-azure \
      --version 1.3.0
    ```

    >Note: Use at least version 1.2.0-rc3, e.g. `--version 1.2.0-rc3`, when installing on k8s version >= 1.16

    Alternatively you can combine the `helm-config.yaml` and the Helm command in one step:
    ```bash
    helm install ingress-azure application-gateway-kubernetes-ingress/ingress-azure \
         --namespace default \
         --debug \
         --set appgw.name=applicationgatewayABCD \
         --set appgw.resourceGroup=your-resource-group \
         --set appgw.subscriptionId=subscription-uuid \
         --set appgw.usePrivateIP=false \
         --set appgw.shared=false \
         --set armAuth.type=servicePrincipal \
         --set armAuth.secretJSON=$(az ad sp create-for-rbac --sdk-auth | base64 -w0) \
         --set rbac.enabled=true \
         --set verbosityLevel=3 \
         --set kubernetes.watchNamespace=default \
         --version 1.3.0
    ```

    >Note: Use at least version 1.2.0-rc3, e.g. `--version 1.2.0-rc3`, when installing on k8s version >= 1.16

1. Check the log of the newly created pod to verify if it started properly
 
 
## Dep[oy the application to the AKS cluster
