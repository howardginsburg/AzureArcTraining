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

    - `curl https://raw.githubusercontent.com/howardginsburg/AzureArcTraining/main/deploy.sh | bash`
    - The username is `azurearc` and the password is `LearnArc123!`

## 2. Access your servers

1. Enable JIT for both servers from the Configuration blade for each VM.
2. Request JIT access for each server from the Connect blade for each VM.
3. ssh into the Ubuntu VM and let the login script run to disable Azure resources.
4. rdp into the Windows VM and let the login script run to disable Azure resources.

## 3. Onboard Servers to Azure Arc

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

## 4. Deploy an Azure Policy for your Servers.

This step assigns several policies to the resource group which ensures that as the Arc Servers come online, the Azure Monitor Agent and Dependency Agent get installed and are configured to route data to our Log Analytics workspace via the Data Collection rule policy.

For this tutorial, we are going to use policy to enable the Linux VM.  We will manually bring the Windows VM online in later steps.

1. Access your resource group within the Azure Portal.
2. Select the 'Policies' blade.
3. Select the 'Definitions' blade.
4. Enable the following policies for the Arc Resource Group.

    - [Preview]: Deploy a VMInsights Data Collection Rule and Data Collection Rule Association for Arc Machines in the Resource Group
        - On the Parameters blade
            - Uncheck 'Only show parameters that need input of review'.
            - Select your Log Analytics Workspace.
            - Set 'Enable Processes and Dependencies' to 'true'.
        - On the Remediation blade
            - Check 'Create a remediation task'.
            - Set the System assigned managed identity location to 'West US'.
    - Configure Linux Arc-enabled machines to run Azure Monitor Agent
        - On the Remediation blade
            - Check 'Create a remediation task'.
            - Set the System assigned managed identity location to 'West US'.
    - Configure Dependency agent on Azure Arc enabled Linux servers with Azure Monitoring Agent settings
        - On the Remediation blade
            - Check 'Create a remediation task'.
            - Set the System assigned managed identity location to 'West US'.

    The policies that can enable the same behavior for Windows VMs are

    - Configure Windows Arc-enabled machines to run Azure Monitor Agent
    - Configure Dependency agent on Azure Arc enabled Windows servers with Azure Monitoring Agent settings

5. Return to the 'Policies' blade of your Resource Group and view the Compliance blade.  You will see that you are 100%.  It can take up to 30 minutes for policies to be checked and remediated.

Note, there are many [built-in](https://docs.microsoft.com/en-us/azure/azure-arc/servers/policy-reference) policy definitions for Azure Arc to consider.

## 5. Setup Insights on Windows Server

1. Open your Arc Server for Windows VM in the Portal.
2. Select 'Insights'
3. Click on 'Enable'
4. Select to use the 'Azure Monitor Agent'
5. Select to create a new data collection rule.
6. Give your data collection rule a name.
7. Check to 'Enable processes and dependencies'.
8. Select your Log Analytics Workspace.
9. Click on 'Create'.
10. Click on 'Configure'.
11. Click on the Extensions blade and notice the AzureMonitorWindowsAgent and DependencyAgentWindows is being deployed to your Arc VM.

## 6. Monitor Azure Policy for Linux VMs

1. Select your Arc Resource Group in the Portal.
2. Select Policies.
3. Select the Compliance blade to view the status of all the policies assigned to the resource group.
4. Select the Remediation blade to view all the policies that have remediation tasks associated with them.
5. Select 'Remediation Tasks' to view tasks that are underway.

In time, you will see a new Data Collection Rule resource created in the portal.  You will also see the AzureMonitorLinuxAgent and DependencyAgentLinux extensions were deployed to your Arc Linux VM.

But WAIT!  We now have two Data Collection Rules.  And if I look at the 'Monitoring configuration' on the 'Insights' blade of my Windows VM, the rule I created is no longer mapped to it.  That's the power of the Azure Policy!  You can delete the data collection rule you created if you want.

## 7. Onboard Azure Kubernetes as an Arc Kubernetes resource

1. Open a bash terminal that is not Azure Cloud Shell.
2. Get your credentials.
    `az aks get-credentials --resource-group <Your Resource Group> --name <Your Cluster>`
3. Install the connectedk8s extension
    `az extension add --name connectedk8s`
4. Install Helm
    `curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3`
    `bash get_helm.sh`
5. Connect your cluster
    `az connectedk8s connect --name arcakscluster --resource-group <Your Resource Group`

## 8. Enable Insights on Arc Kubernetes

1. Open your Kubernetes Arc Cluster in the Azure Portal.
2. Select the 'Insights' blade.
3. Select configure 'Azure Monitor'
4. Select your Log Analytics Workspace.
5. Check 'Use managed identity'.
6. Select Configure.
7. Select the 'Extensions' blade and see that the azuremonitor-containers extension is installing.

Note, it will take some time before the metrics show up in the 'Insights' blade.

## TODO 5. Azure Automation Setup

1. Access your Azure Automation account within the Portal.
2. Select the 'Inventory'.
3. Select your Log Analytics workspace.
4. Select 'Enable'.
5. Select the 'Update Management' blade.
6. Select your Log Analytics workspace.
7. Select 'Enable'.

## Resource Cleanup

### Option 1: Delete the Resource Groups

The easiest thing to get rid of all the resources is just to delete the two Resource Groups created as part of this exercise.

### Option 2: Stop the resources

1. On the 'Overview' blade for each Azure server click 'Stop'.
2. You can start/stop your AKS cluster with the following command
    `az aks <start or stop> --name myAKSCluster --resource-group myResourceGroup` 

## Troubleshooting

1. The Azure policy that creates the Data Collection Rule may interfere with the proper deployment of the Extensions for Windows since it will move the mapping.  If this occurs, remove the Extensions and then enable Insights again selecting the data collection rule that the policy created.