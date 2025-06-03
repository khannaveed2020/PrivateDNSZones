function PrivateDNSZoneDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $VNetResourceId,

        [Parameter(Mandatory = $false)]
        [string]
        $FQDN
    )

    try {
        # Validate VNet Resource ID format
        if (-not ($VNetResourceId -match '^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$')) {
            throw "Invalid VNet Resource ID format. Expected format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Network/virtualNetworks/{vnetName}"
        }

        # Get the subscription ID and resource group from the VNet Resource ID
        $vnetParts = $VNetResourceId -split '/'
        $subscriptionId = $vnetParts[2]
        $resourceGroup = $vnetParts[4]

        # Set the subscription context
        Set-AzContext -SubscriptionId $subscriptionId

        # Get all private DNS zones in the subscription
        $privateZones = Get-AzPrivateDnsZone
        if (-not $privateZones) {
            Write-Warning "No private DNS zones found in the subscription."
            return $null
        }

        # Get all private DNS zone virtual network links
        $linkedZones = @()
        foreach ($zone in $privateZones) {
            $links = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name
            foreach ($link in $links) {
                if ($link.VirtualNetworkId -eq $VNetResourceId) {
                    $zoneDetails = [PSCustomObject]@{
                        ZoneName = $zone.Name
                        ResourceGroup = $zone.ResourceGroupName
                        ZoneId = "/subscriptions/$subscriptionId/resourceGroups/$($zone.ResourceGroupName)/providers/Microsoft.Network/privateDnsZones/$($zone.Name)"
                        LinkName = $link.Name
                        LinkId = "/subscriptions/$subscriptionId/resourceGroups/$($zone.ResourceGroupName)/providers/Microsoft.Network/privateDnsZones/$($zone.Name)/virtualNetworkLinks/$($link.Name)"
                    }

                    # If FQDN is specified, check for matching records
                    if ($FQDN) {
                        # Validate FQDN format
                        if (-not ($FQDN -match '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$')) {
                            throw "Invalid FQDN format. Please provide a valid fully qualified domain name."
                        }

                        # Check if the FQDN ends with the zone name
                        if ($FQDN -like "*$($zone.Name)") {
                            $records = Get-AzPrivateDnsRecordSet -ResourceGroupName $zone.ResourceGroupName -ZoneName $zone.Name -RecordType A
                            
                            # Find matching A record
                            $matchingRecord = $records | Where-Object { $_.Name -eq ($FQDN -replace "\.$($zone.Name)$", "") }
                            
                            if ($matchingRecord) {
                                $zoneDetails | Add-Member -NotePropertyName 'MatchingFQDN' -NotePropertyValue $FQDN
                                $zoneDetails | Add-Member -NotePropertyName 'ARecord' -NotePropertyValue $matchingRecord.Records.Ipv4Address
                                $zoneDetails | Add-Member -NotePropertyName 'TTL' -NotePropertyValue $matchingRecord.Ttl
                            }
                            else {
                                $zoneDetails | Add-Member -NotePropertyName 'AvailableRecords' -NotePropertyValue ($records | ForEach-Object { 
                                    "$($_.Name).$($zone.Name) -> $($_.Records.Ipv4Address) (TTL: $($_.Ttl))" 
                                })
                            }
                        }
                    }

                    $linkedZones += $zoneDetails
                }
            }
        }

        if (-not $linkedZones) {
            Write-Warning "No private DNS zones found linked to the specified VNet."
            return $null
        }

        return $linkedZones
    }
    catch {
        Write-Error "Error occurred: $_"
        throw
    }
}

Export-ModuleMember -Function PrivateDNSZoneDetails 

