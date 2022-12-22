# AKSWorkshop

  1. Create a Resource Group for the workshop

## Creare Azure Kubernetes Service

   1 Navigate to **Kubernetes services** and click **create**.

   2 Choose your subscription and Resource Group you just created.

   3 **Cluster preset Configuration** - Dev/Test
    
   4 **Kubernetes cluster name** - aksworkshop

   5 **Region** - West Europe

   6 **Availability zones** - None

   7 **Node Size** - Change size to B2s

   8 **Scale method** - Autoscale - min 1 Max 2
    
   9 Click **review + create** 
    
    
## Create a Container Registry (ACR)

   1 Navigate to **Container registries** and click create.

   2 Choose your subscription and Resource Group.

   3 Enter a **uniqe name** for the container registry.

   4 **SKU** - Basic.

   5 Click **Review + create**
 
    
## Build the containers images

  1. Open **Cloud Shell** on the Azure Portal.

  2. Clone this repository - **git clone https://github.com/cloudedgedevops/AKSWorkshop.git**
 
