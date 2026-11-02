# Factorio on Azure Container Instances

Deploy a Linux container group and an Azure Files share mounted at `/factorio`. Saves, mods and configuration survive container replacement as long as you keep the storage account and share.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffactoriotools%2Ffactorio-docker%2Fmaster%2Fconfigs%2FAzure%2FCreateContainer.json)

**Costs:** this creates billable compute and storage. Use a dedicated resource group, check regional ACI availability/quota and pricing, and select the intended subscription before deploying. Stopping or deleting the container does not delete the storage account or stop storage charges.

## Deploy

Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), sign in, and run these commands from `configs/Azure`. Replace the subscription ID and choose an available region.

```sh
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
az group create --name GameResources --location eastus

az deployment group validate \
  --resource-group GameResources \
  --template-file CreateContainer.json

az deployment group create \
  --name factorio \
  --resource-group GameResources \
  --mode Incremental \
  --template-file CreateContainer.json

az deployment group show \
  --name factorio \
  --resource-group GameResources \
  --query properties.outputs \
  --output json
```

Connect using the `serverAddress` output (the assigned FQDN and UDP port 34197). Azure allocates the public IP; it can change when the container is recreated. Do not copy an IP from another deployment or construct the FQDN yourself.

The default storage account and DNS label are derived from the resource group and container group name. You may override them if a name is unavailable. Save any overrides and use the same values for subsequent deployments so the existing data share is reused.

### Parameters

| Parameter | Default | Purpose |
| --- | --- | --- |
| `location` | Resource group's region | Region supporting ACI and the selected storage redundancy |
| `containerGroupsName` | `factorio` | Container group name; lowercase letters, digits and hyphens |
| `storageAccountName` | Generated | Globally unique name of 3–24 lowercase letters/digits |
| `dnsPrefix` | Generated | DNS label; lowercase letters, digits and hyphens |
| `storageAccountType` | `Standard_LRS` | `Standard_LRS`, `Standard_GRS` or `Standard_ZRS`, subject to regional availability |
| `cpuCores` | `2` | Requested CPU cores; regional capacity and subscription quota apply |
| `memoryInGb` | `4` | Requested memory; large saves and mods may need more |
| `factorioVersion` | `stable` | Regular image tag; pin a version matching your clients for controlled upgrades |

For example, append `--parameters factorioVersion=2.1.24 cpuCores=2 memoryInGb=8` to **both** validation and deployment commands to select that version and memory size. An existing save may not be compatible with a downgrade. Keep resource names, location and storage settings unchanged during upgrades.

## First start and server configuration

The image initializes files in the `factorio` share, including `config/server-settings.json`. Use the Azure portal's Storage browser or Azure Storage Explorer to edit them. The default settings may require configuration before the server will host successfully:

- For an unlisted server, set `visibility.public` to `false`.
- For a public listing, configure your Factorio `username` and `token` in the settings file.
- Configure `game_password` and/or the whitelist before inviting players. An unlisted server still has a publicly reachable UDP port.
- Use compatible client/server Factorio versions, DLC settings and mods.

Do not commit credentials or storage keys to this template. The storage key is obtained by ARM for the mount and is not emitted in deployment outputs.

After changing settings, restart the container (replace the name if you changed `containerGroupsName`):

```sh
az container restart --resource-group GameResources --name factorio
az container logs --resource-group GameResources --name factorio
```

### Azure Files permissions and RCON

[ACI requires Azure Files containers to run as root and mounts shares using CIFS](https://learn.microsoft.com/azure/container-instances/container-instances-volume-azure-files#limitations). This template therefore uses the **regular** image with `PUID=0` and `PGID=0`. Do not select a `-rootless` tag. This is an Azure Files compatibility choice, not a recommendation for other deployments; the server has root access inside its container and to its mounted share.

Only UDP 34197 is published. RCON TCP 27015 is deliberately **not** exposed to the internet. To administer the server, use an authenticated Azure CLI session:

```sh
az container exec --resource-group GameResources --name factorio --exec-command /bin/bash
```

Inside that shell, use `rcon`, for example `rcon /server-save`. The client reads the generated password from `/factorio/config/rconpw`; do not publish that password. Save and confirm completion in the logs before stopping or replacing a server.

## Upgrade without deleting game data

Back up the Azure Files share first. Stop the container, delete **only the container group**, then repeat the deployment command with the same resource/storage names and the desired `factorioVersion`:

```sh
az container stop --resource-group GameResources --name factorio
az container delete --resource-group GameResources --name factorio
```

Redeployment is incremental and reuses the share. Restarting a container is not a substitute for redeploying to select a new image version. Do not delete the storage account, share or resource group during an upgrade.

## Validation and troubleshooting

The repository tests the template's dependency chain, persistence wiring, networking and safe defaults, and runs Microsoft's ARM Template Toolkit. These are offline checks, **not proof of a successful Azure deployment or multiplayer connection**. Before relying on a deployment, verify:

1. Creation from an empty resource group and successful startup after configuring server settings.
2. A real client can join the FQDN on UDP 34197.
3. A saved world survives stop/start and container-only deletion/redeployment with unchanged storage parameters.

If a client stalls at “waiting for the server to save the map”, inspect server logs, available memory/CPU and Azure Files I/O, then reproduce with a small unmodded save and matching client version. An `EOF on stdin` log message alone does not establish why multiplayer failed. The historical connection report on PR #413 was not reproduced or root-caused by the template's offline tests.

If provisioning fails, inspect `az deployment group show --name factorio --resource-group GameResources`, verify resource-provider registration, region/quota/name availability, and check access to Azure Files (SMB requires outbound TCP 445). The template explicitly waits for the file share before creating the container group.

For full cleanup, delete the dedicated resource group only after backing up anything you need. **Deleting the group permanently deletes the saves and configuration in its storage account.**
