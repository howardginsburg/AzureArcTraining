#Variables
user="azurearc"
password='LearnArc123!'
location="westus"

#Ask for the IP Address so we can define nsg rules.
#read -p "What's your IP Address (https://whatismyipaddress.com/): " ipaddress

rand=$((100 + $RANDOM % 1000))

#Create a resource group.
resourceGroup="arcdemo$rand"
az group create --name $resourceGroup --location $location

#Create a VNet and NSG rules to open SSH and RDP
az network nsg create --resource-group $resourceGroup --name "arcnsg$rand" --location "$location"
#az network nsg rule create --resource-group $resourceGroup --nsg-name "arcnsg$rand" --name Allow-SSH-IP --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix $ipaddress --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22
#az network nsg rule create --resource-group $resourceGroup --nsg-name "arcnsg$rand" --name Allow-RDP-IP --access Allow --protocol Tcp --direction Inbound --priority 301 --source-address-prefix $ipaddress --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3389
az network vnet create -g $resourceGroup -n "arcvnet$rand" --address-prefix 10.0.0.0/16 --subnet-name default --subnet-prefix 10.0.0.0/24 --network-security-group "arcnsg$rand"

#Create a ubuntu vm and deploy a login script that will stop the azure agents and enable the firewall on the vm to prevent it from communicating with the Azure Instance Metadata Service (IMDS)
#NOTE: Use Ubuntu 18 on Azure.  The DependencyAgent Extension that installs when you enable Insights in Arc fails on a Ubuntu 20 Azure VM
#ubuntuimage="Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest" 
ubuntuimage="Canonical:UbuntuServer:18.04-LTS:latest"
az vm create --resource-group $resourceGroup --name "arcubuntuvm$rand" --image $ubuntuimage --admin-username $user --admin-password $password --size Standard_D4s_v3 --vnet-name "arcvnet$rand" --subnet "default" --nsg "" --public-ip-address-allocation static
wget https://raw.githubusercontent.com/howardginsburg/AzureArcTraining/main/ubuntulogin.sh
az vm run-command invoke -g $resourceGroup -n "arcubuntuvm$rand" --command-id RunShellScript \
    --scripts @ubuntulogin.sh \
    --parameters "$user arcubuntuvm$rand"
rm ubuntulogin.sh

#Create a windows vm and deploy a login script that will stop the azure agents and enable the firewall on the vm to prevent it from communicating with the Azure Instance Metadata Service (IMDS)
windowsimage="MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest"
az vm create --resource-group $resourceGroup --name "arcwinvm$rand" --image $windowsimage --admin-username $user --admin-password $password --size Standard_D4s_v3 --vnet-name "arcvnet$rand" --subnet "default" --nsg "" --public-ip-address-allocation static
wget https://raw.githubusercontent.com/howardginsburg/AzureArcTraining/main/windowslogin.ps1
az vm run-command invoke  --command-id RunPowerShellScript --name "arcwinvm$rand" -g $resourceGroup  \
    --scripts @windowslogin.ps1 \
    --parameters "adminUserName=$user"
rm windowslogin.ps1

#Create an instance of log analytics and azure automation to speed arc setup by the user.
az monitor log-analytics workspace create -g $resourceGroup -n "arcworkspace$rand"
az automation account create --automation-account-name "arcautomation$rand" --resource-group $resourceGroup
