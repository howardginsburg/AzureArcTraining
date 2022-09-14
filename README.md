# Azure Arc for Servers

The purpose of this repo is to serve as a quickstart for hands on training for Azure Arc for Servers.  It will setup two Azure vms and create login scripts that will reconfigure them to appear as non-Azure resources.

Note: As Arc is meant to be used with on-prem environments, leveraging Azure is not without certain issues.  For example, the Dependency Agent that gets deployed when you enable Insights on your server will fail on an Azure Ubuntu 20.04 VM.  It works fine when deployed against a regular Ubuntu 20.04 instance.

The build out of this environment leverages a similar login script pattern as defined in the [Azure ArcBox](https://azurearcjumpstart.io/azure_jumpstart_arcbox/) deployment.  Those scripts disable the Azure components which are based on the documentation to [Test Arc-enabled servers using an Azure VM](https://docs.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine)

## 1. Deploy Resources

This the deployment script will create the following assets in Azure:

- Ubuntu 18.04 server
- Windows 2022 server
- Log Analytics Workspace
- Azure Automation Account

1. From an Azure Cloud Shell bash session

    - `curl https://raw.githubusercontent.com/howardginsburg/AzureArcTraining/main/deployarcservers.sh | bash`
    - The username is `azurearc` and the password is `LearnArc123!`

## 2. Deploy an Azure Policy

This step assigns several policies to the resource group which ensures that as the Arc Servers come online, the Azure Monitor Agent nd Dependency Agent get installed and are configured to route data to our Log Analytics workspace via the Data Collection rule policy.

1. Access your resource group within the Azure Portal.
2. Select the 'Policies' blade.
3. Select the 'Definitions' blade.
4. Enable the following policies for the Arc Resource Group.

    - Configure Linux Arc-enabled machines to run Azure Monitor Agent
    - Configure Windows Arc-enabled machines to run Azure Monitor Agent
    - [Preview]: Deploy a VMInsights Data Collection Rule and Data Collection Rule Association for Arc Machines in the Resource Group
    - Configure Dependency agent on Azure Arc enabled Linux servers with Azure Monitoring Agent settings
    - Configure Dependency agent on Azure Arc enabled Windows servers with Azure Monitoring Agent settings

5. Return to the 'Policies' blade of your Resource Group and view the Compliance blade.  You will see that you are 100%.  It can take up to 30 minutes for policies to be checked and remediated.

Note, there are many [built-in](https://docs.microsoft.com/en-us/azure/azure-arc/servers/policy-reference) policy definitions for Azure Arc to consider.

## 3. Access your servers

1. Enable JIT for both servers from the Configuration blade for each VM.
2. Request JIT access for each server from the Connect blade for each VM.
3. ssh into the Ubuntu VM and let the login script run to disable Azure resources.
4. rdp into the Windows VM and let the login script run to disable Azure resources.

## 4. Onboard to Azure Arc

1. Search for 'Arc' in the Azure Portal and select 'Azure Arc'.
2. Select the 'Servers' blade.
3. Select '+ Add'.
4. Select 'Generate Script' from 'Add a single server'.
5. Select your Resource Group and correct operating system.
6. Fill in the Resource Tags.
7. Copy the contents of the script.
8. Access your server and save the contents as either a .sh (Linux) or ps1 (Windows) file.
9. Run your file.
10. Follow the device login instructions.
11. Verify that the servers now appear as 'Arc Server' within your resource group.

## 5. Azure Automation Setup

1. Access your Azure Automation account within the Portal.
2. Select the 'Inventory'.
3. Select your Log Analytics workspace.
4. Select 'Enable'.
5. Select the 'Update Management' blade.
6. Select your Log Analytics workspace.
7. Select 'Enable'.

## 6. 