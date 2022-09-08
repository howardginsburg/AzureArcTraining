# Azure Arc for Servers

The purpose of this repo is to serve as a quickstart for hands on training for Azure Arc for Servers.  This the deployment script will create the following assets in Azure:

1. Ubuntu 18.04 server
2. Windows 2022 server 
3. Log Analytics Workspace
4. Azure Automation Account

The script also creates first time login scripts for both servers that disable the Azure components and communication that are part of a standard Azure VM deployment.

Note: As Arc is meant to be used with on-prem environments, leveraging Azure is not without certain issues.  For example, the Dependency Agent that gets deployed when you enable Insights on your server will fail on an Azure Ubuntu 20.04 VM.  It works fine when deployed against a regular Ubuntu 20.04 instance.

This script leverages aspects of [Azure ArcBox](https://azurearcjumpstart.io/azure_jumpstart_arcbox/) deployment.  In particular, the login scripts that disable the Azure components.

## Getting started

1. From an Azure Cloud Shell bash session `curl https://raw.githubusercontent.com/howardginsburg/AzureArcTraining/main/deployarcservers.sh | bash`
  - The username is `azurearc` and the password is `LearnArc123!`
2. Enable JIT for both servers from the Configuration blade for each VM.
3. Request JIT access for each server from the Connect blade for each VM.
4. ssh into the Ubuntu VM and let the login script run to disable Azure resources.
5. rdp into the Windows VM and let the login script run to disable Azure resources.
