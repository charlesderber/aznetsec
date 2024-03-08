param location string = 'norwayeast'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'hub-vNet'
  location: location
  properties: {
    subnets: [
      {
        name: 'default'
        properties: {
          routeTable: {
            id: routeTable.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroups.id
          }
          addressPrefixes: [
            '10.0.0.0/24'
          ]
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefixes: [
            '10.0.1.0/26'
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefixes: [
            '10.0.2.0/26'
          ]
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'hub-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'rule1'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'rule2'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 200
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          destinationApplicationSecurityGroups: [
            {
              id: applicationSecurityGroup.id
            }
          ]
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: 'hubRoute'
  location: location
  properties: {
    routes: [
      {
        name: 'internet'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.0.0.4'
        }
      }
    ]
  }
}

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2023-05-01' = {
  name: 'sharedServers'
  location: location
}

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'fw-PIP'
  location: location
  zones: [
    '1'
  ]
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'bas-PIP'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

var vNetresourceId = virtualNetwork.id
var bastionSubnetId = '${vNetresourceId}/subnets/AzureBastionSubnet'

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: 'hub-bastion'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    scaleUnits: 2
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
             id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPIP.id
          }
        }
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: 'hub-firewall'
  location: location
  zones: [
    '1'
  ]
  tags: {}
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: firewallPIP.name
        properties: {
          subnet: virtualNetwork.properties.subnets[1]
          publicIPAddress: {
            id: firewallPIP.id
          }
        }
      }
    ]
  }
}
