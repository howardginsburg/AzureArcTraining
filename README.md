# Azure Arc for Servers and Kubernetes

The purpose of this repo is to serve as a quickstart for hands on training for Azure Arc for Servers and Kubernetes.

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

## 2. Create a Service Principal

We will use a service principal to onboard resources into Arc.

1. From an Azure Cloud Shell bash session

    - `subscriptionId=$(az account show --query id --output tsv)`
    - `az ad sp create-for-rbac -n "<Your Unique Name>" --role "Azure Connected Machine Onboarding" --scopes /subscriptions/$subscriptionId`
    - Save the results of the output for later use!

## 3. Access your servers

### Option 1

    1. Enable JIT for both servers from the Configuration blade for each VM.
    2. Request JIT access for each server from the Connect blade for each VM.
    3. ssh into the Ubuntu VM and let the login script run to disable Azure resources.
    4. rdp into the Windows VM and let the login script run to disable Azure resources.

### Option 2

    1. Edit the ingress rules of the network security group to enable ports 22 and 3389.

## 4. Onboard Servers to Azure Arc

1. Search for 'Arc' in the Azure Portal and select 'Azure Arc'.
2. Select the 'Servers' blade.
3. Select '+ Add'.
4. Select 'Generate Script' from 'Add multiple servers'.
5. Select your Resource Group and correct operating system.
6. Select your Service Principal.
7. Fill in the Resource Tags.
8. Copy the contents of the script.
    - Replace the secret with the password of your service principal.
    - Note: For the Windows script, there is a bug with what gets generated.  The $servicePrincipalClientId and $servicePrincipalSecret have the semicolon inside the quote instead of at the end.
9. Access your server and save the contents as either a .sh (Linux) or ps1 (Windows) file.
10. Run your file.
11. Verify that the servers now appear as 'Arc Server' within your resource group.
12. On your linux vm, running the following command to see what the Arc Agent is communicating with.

    - `sudo lsof -ai -p $(pidof himds)`

## 5. Deploy an Azure Policy for your Servers

This step assigns several policies to the resource group which ensures that as the Arc Servers come online, the Log Analytics Agent and Dependency Agent get installed.

For this tutorial, we are going to use policy to enable the Linux VM.  We will manually bring the Windows VM online in later steps.

### Option 1 - Log Analytics Agent

    1. Access your resource group within the Azure Portal.
    2. Select the 'Policies' blade.
    3. Select the 'Definitions' blade.
    4. Enable the following policies for the Arc Resource Group.
    
        - Configure Log Analytics extension on Azure Arc enabled Linux servers.
            - On the Parameters blade
                - Select your log analytics workspace.
            - On the Remediation blade
                - Check 'Create a remediation task'.
                - Set the System assigned managed identity location to 'West US'.
        - Configure Dependency agent on Azure Arc enabled Linux servers
            - On the Remediation blade
                - Check 'Create a remediation task'.
                - Set the System assigned managed identity location to 'West US'.
    
        The policies that can enable the same behavior for Windows VMs are
    
        - Configure Log Analytics extension on Azure Arc enabled Windows servers
        - Configure Dependency agent on Azure Arc enabled Windows servers
    5. Return to the 'Policies' blade of your Resource Group and view the Compliance blade.  You will see that you are 100%.  It can take up to 30 minutes for policies to be checked and remediated.

### Option 2 - Azure Monitor Agent

    Alternatively, you can use the new Azure Monitor Agent which is in preview.  It should be noted that at this time, not all capabilities are supported.  This includes the ability to use Inventory, Change Tracking, and onboarding to Azure Sentinel.  The policies for those are

    - [Preview]: Deploy a VMInsights Data Collection Rule and Data Collection Rule Association for Arc
    - Configure Linux Arc-enabled machines to run Azure Monitor Agent
    - Configure Dependency agent on Azure Arc enabled Linux servers with Azure Monitoring Agent settings
    - Configure Windows Arc-enabled machines to run Azure Monitor Agent
    - Configure Dependency agent on Azure Arc enabled Windows servers with Azure Monitoring Agent settings

Note, there are many [built-in](https://docs.microsoft.com/azure/azure-arc/servers/policy-reference) policy definitions for Azure Arc to consider.

## 6. Setup Insights on Windows Server

### Option 1 - Log Analytics Agent

    1. Open your Arc Server for Windows VM in the Portal.
    2. Select 'Insights'
    3. Click on 'Enable'
    4. Select to use the 'Log Analytics Agent'
    5. Select your Log Analytics Workspace.
    6. Click on 'Configure'.
    7. Click on the Extensions blade and notice the AzureMonitorWindowsAgent and DependencyAgentWindows is being deployed to your Arc VM.

### Option 2 - Azure Monitor Agent

    Alternatively, you can use the new Azure Monitor Agent which is in preview.  It should be noted that at this time, not all capabilities are supported.  This includes the ability to use Inventory, Change Tracking, and onboarding to Azure Sentinel
    
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

## 7. Monitor Azure Policy for Linux VMs

1. Select your Arc Resource Group in the Portal.
2. Select Policies.
3. Select the Compliance blade to view the status of all the policies assigned to the resource group.
4. Select the Remediation blade to view all the policies that have remediation tasks associated with them.
5. Select 'Remediation Tasks' to view tasks that are underway.

## 8. Optional - Collect Server Logs

The Log Analytics Agent and Azure Monitor Agent do not capture server logs by default and can be enabled if you need them.

### Option 1 - Log Analytics Agent

    1. Select your Log Analytics Workspace in the Azure Portal.
    2. Select the 'Legacy agents management' blade.
    3. Add the logs and/or perfomance counters you're interested in collecting.

### Option 2 - Azure Monitor Agent

    The Log Analytics Data Collection Rule that gets created when you enable 'Insights' only captures Performance Counters.  Microsoft [documentation](https://docs.microsoft.com/azure/azure-monitor/vm/vminsights-enable-overview#data-collection-rule-azure-monitor-agent) recommends creating separate data collection rules for these items.
    
    1. Select your Log Analytics Workspace in the Azure Portal.
    2. Select the 'Agents Management' blade.
    3. Click on 'Data Collection Rules'.
    4. Click on 'Create'.
    5. On the Basics tab
        - Enter a 'Rule Name'.
        - Select your Arc Resource Group.
        - Select the region to 'West US'.
        - Set the Platform Type to 'Custom'.
    6. On the Resources tab
        - Click 'Add resources'
        - Select both of your Arc servers.
    7. On the Collect and Deliver tab
        - Click on 'Add data source' and select the items you're interested in collecting.

## 9. Optional - Inventory and Change tracking

1. Open your Azure Automation account in the Portal.
2. Select the 'Inventory' blade.
3. Select your Log Analytics Workspace.
4. Click 'Enable'.
5. After deployment completes, refresh the Portal.
6. Click 'Manage machines'.
7. Select 'Enable on selected machines'.
8. Add your two vms.
9. Click 'Enable'.

Note, it will take some time before data shows up.

## 10. Optional - Update Management

In this lab, we will explore the new Update Management capabilities in Azure.  This feature is currently in preview and not supported in all [regions](https://learn.microsoft.com/azure/update-center/support-matrix?tabs=azurearc%2Cazurevm-os#supported-regions).  Thus, our Arc VM's are being configured to map to South Central US.

1. Open your Azure Automation account in the Portal.
2. Select the 'Update Management' blade.
3. Select your Log Analytics Workspace.
4. Click 'Enable'.
5. After deployment completes, refresh the Portal.
6. Click 'Manage machines'.
7. Select 'Enable on selected machines'.
8. Add your two vms.
9. Click 'Enable'.
10. Using the Azure Portal search bar, open the Update Management Center.
11. Select the 'Machines' blade.
12. Check each of your arc vms and click 'Update settings'.
13. Check 'Periodic assessment'
14. Check 'Enable Periodic assessment(every 24 hours)'
15. Click 'Next' and see your two arc vms listed.
16. Click 'Next'.
17. Click 'Review and change'.

Note, it will take some time before the assessment is run and data shows up.  Once you see data, you can schedule an update.  Also look at the extensions on your Arc VM's and see that the Update extension has been installed.

## 11. Onboard Kubernetes as an Arc Kubernetes resource

Note:Make sure you have followed the [prerequiste](https://github.com/howardginsburg/AzureArcTraining/wiki/Arc-Day-Prerequisites) instructions and set up the environment accordingly.

1. Connect Your Kubernetes to Azure via Azure Arc.
  
    - `az connectedk8s connect -g <your arc resource group> -n <your arc enabled cluster name> --kube-config quickstart-azure-custom.YAML`

2. Go to Azure portal check arc enabled kubernetes is created and also check

    - check Azure Arc agents as pods & deployments
    - kubectl get deployments,pods -n azure-arc

3. Connect Azure Kubernetes Control Pane to K3S

    - Option#1: Azure Active Directory authentication option
    - Option#2: [Service account token](https://learn.microsoft.com/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-powershell#service-account-token-authentication-option) authentication option
    - We will use Option#2 & create a token (Powershell or CLI)

4. Go to Azure portal connect to Azure Kubernetes control pane using token generated in Step.3 -Option#2.

    - Optional: Try any of the Kubernetes day lab using the Azure Control Pane for Kubernetes.

## 12. Enable Insights on Arc Kubernetes

1. Open your Kubernetes Arc Cluster in the Azure Portal.
2. Select the 'Insights' blade.
3. Select 'Configure azure monitor'
4. Select your Log Analytics Workspace.
5. Check 'Use managed identity'.
6. Select Configure.
7. Select the 'Extensions' blade and see that the azuremonitor-containers extension is installing.

Note, it will take some time before the metrics show up in the 'Insights' blade.

## 13. Defender for Cloud

In this lab we will explore [Defender for Cloud and Azure Arc](https://learn.microsoft.com/azure/cloud-adoption-framework/manage/hybrid/server/best-practices/arc-security-center).  Many organizations enable policies at the Tenant level which will automatically enable Defender capabilities at all subscriptions.  You may see some of these steps already completed.  All Azure subscriptions come with the Basic tier.  The Standard tier has a free 30 day trial.

1. Search for Defender for Cloud.
2. Select the 'Environment Settings' blade.
3. Click 'Expand all' and select your Azure subscription.
4. Set the 'Servers' and 'Containers' options to 'On'.

It will take some time before your resources are scored and suggestions made.

Note, some organizations also subscribe to Defender for Endpoint Protection.  If this is the case, and certain policy is enabled, you may see the agent (MDE.Linux or MDE.Windows) automatically installed on your servers.

## Resource Cleanup

### Option 1: Delete the Resource Groups

The easiest thing to get rid of all the resources is just to delete the two Resource Groups created as part of this exercise.

### Option 2: Stop the resources

1. You can start/stop your Azure VMs with the following command
    `az vm <start or stop> --ids $(az vm list --resource-group <Your Resource Group> --query "[].id" -o tsv )`

1. You can start/stop your AKS cluster with the following command
    `az aks <start or stop> --name <Your AKS Cluster Name> --resource-group <Your Resource Group>`

## Troubleshooting

1. The Azure policy that creates the Data Collection Rule may interfere with the proper deployment of the Extensions for Windows since it will move the mapping.  If this occurs, remove the Extensions and then enable Insights again selecting the data collection rule that the policy created.
