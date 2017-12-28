# Powreshell Script to create a Resource Group,Storage,Virtual Network (with configured IP and SUbnet),VM in West Europe Datacenter,
# Written by Chris Proud


# Login to Azure
Login-AzureRmAccount



Select-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise"



# Create a new resource group
New-AzureRmResourceGroup -Name CP-ResourceGroup-01 -Location westeurope




#Create Blob Storage account
New-AzureRmStorageAccount -ResourceGroupName CP-ResourceGroup-01 -Name cpblobstorage01 -SkuName Standard_LRS -Location westeurope




# Create a subnet configuration
$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name CP-Subnet-01 -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName CP-ResourceGroup-01 -Location westeurope `
-Name CP-vNET-01 -AddressPrefix 192.168.0.0/16 -Subnet $subnetconfig

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName CP-ResourceGroup-01 -Location westeurope `
-AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "cppublicdns$(Get-Random)"




# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -name CPNetworkSecurityGroupRuleRDP -Protocol Tcp `
-Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 3389 -Access Allow

# Create an inbound network securiy group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name CPNetworkSecurityGroupRuleWWW -Protocol Tcp `
-Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 80 -Access Allow

# Create a network security group
$nsg= New-AzureRmNetworkSecurityGroup -ResourceGroupName CP-ResourceGroup-01 -Location westeurope `
-Name Cp-NetowrkSecurityGroup-01 -SecurityRules $nsgRuleRDP, $nsgRuleWeb




# Create a virtual network card and associate with public IP and NSG
$nic = New-AzureRmNetworkInterface -Name CPNic -ResourceGroupName CP-ResourceGroup-01 -Location westeurope `
-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id




# Define a credential object
$cred = Get-Credential

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName CP-TestVM -VMSize Standard_DS2 | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName CP-TestVM -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
-Skus 2016-datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id




# Create VM
New-AzureRmVM -ResourceGroupName CP-ResourceGroup-01 -Location westeurope -vm $vmConfig