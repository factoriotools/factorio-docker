
# Create a resource group to associate the container with
To create Azure resources they must be associated with a resource group. You can create a new resource group with the following:

`az group create --name GameResources --location eastus`

where `GameResources` is the name of the resource group and `eastus` is the Azure location you want the resources associated with. You can modify either of these to your needs.

# Create the container and storage account for the resource group
Customize CreateContainer.json, specifically the following:
- dnsPrefix.defaultValue: This is a unique prefix to give to your dns address which will be used to connect to your container. The final form will be `dnsPrefix-factorio.eastus.azurecontainer.io` assuming your resource group is in the eastus location.
- variables.cpuCores: The number of cores for the container
- variables.memoryInGb: The memory of the container

Then run the following command which will create the storage account (unless it already exists) and container instance

`az deployment group create --resource-group GameResources --template-file CreateContainer.json`

# Customizing settings
After you have created the container, it will initialize all of its configuration in the storage account which can be accessed through the [Azure Portal](https://portal.azure.com/). After customizing the settings restart the container with:

`az container restart --resource-group GameResources --name factorio`

where `GameResouces` is your resource group and `factorio` is the name of your container group.

# Updating the container
Since all of the game data is persisted in the storage account, updating the container is just deleting and creating it again. This can be done with:

`az container delete --resource-group GameResources --name factorio`

`az deployment group create --resource-group GameResources --template-file CreateContainer.json`

where `GameResouces` is your resource group and `factorio` is the name of your container group.