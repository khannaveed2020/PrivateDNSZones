# PrivateDNSZones

A PowerShell module to retrieve private DNS zones linked to an Azure Virtual Network.

## Installation

```powershell
Install-Module -Name PrivateDNSZones -Scope CurrentUser
```

## Prerequisites

- PowerShell 5.1 or later
- Azure PowerShell modules:
  - Az.Accounts
  - Az.PrivateDns

## Usage

1. First, connect to Azure:

```powershell
Connect-AzAccount
```

2. List available Virtual Networks to get the VNet name and Resource Group:

```powershell
Get-AzVirtualNetwork | select name, ResourceGroupName
```

3. Get the Virtual Network object:

```powershell
$VNet = Get-AzVirtualNetwork -Name "<VNet_Name>" -ResourceGroupName "<RG_Name>"
```

4. Get all private DNS zones linked to the VNet:

```powershell
PrivateDNSZoneDetails -VNetResourceId $VNet.ID
```

5. To look up a specific FQDN in the private DNS zones:

```powershell
PrivateDNSZoneDetails -VNetResourceId $VNet.ID -FQDN "<FQDN_For_Lookup_in_PrivateDNS_Zone>"
```

## Output

The cmdlet returns an array of objects with the following properties:
- ZoneName: Name of the private DNS zone
- ResourceGroup: Resource group containing the DNS zone
- ZoneId: Resource ID of the DNS zone
- LinkName: Name of the VNet link
- LinkId: Resource ID of the VNet link
- MatchingFQDN: The FQDN that was found (when using -FQDN parameter)
- ARecord: The IP address associated with the FQDN (when using -FQDN parameter)
- TTL: Time-to-live value for the DNS record (when using -FQDN parameter)
- AvailableRecords: List of all A records in the zone (when FQDN is not found)

## Example

```powershell
# Connect to Azure
Connect-AzAccount

# List VNets
Get-AzVirtualNetwork | select name, ResourceGroupName

# Get specific VNet
$VNet = Get-AzVirtualNetwork -Name "my-vnet" -ResourceGroupName "my-rg"

# Get all linked private DNS zones
$linkedZones = PrivateDNSZoneDetails -VNetResourceId $VNet.ID
$linkedZones | Format-Table -AutoSize

# Look up specific FQDN
$dnsDetails = PrivateDNSZoneDetails -VNetResourceId $VNet.ID -FQDN "app1.privatelink.blob.core.windows.net"
$dnsDetails | Format-Table -AutoSize
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 