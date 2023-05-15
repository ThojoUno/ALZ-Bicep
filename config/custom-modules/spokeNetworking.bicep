// This module has been modified from the upstream-releases version v0.14.0
// ALZ-Bicep does not have a complete module for spokeNetworking, so utilizing CARML modules/Bicep registry


metadata name = 'ALZ Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Switch to enable/disable BGP Propagation on route table.')
param parDisableBgpRoutePropagation bool = false

@sys.description('Id of the DdosProtectionPlan which will be applied to the Virtual Network.')
param parDdosProtectionPlanId string = ''

@sys.description('The IP address range for all virtual networks to use.')
param parSpokeNetworkAddressPrefixes array = [
  '10.11.0.0/16'
]

param parEnvironmentSuffix string = 'prod'

@sys.description('The Name of the Spoke Virtual Network.')
param parSpokeNetworkName string = 'vnet-${parLocation}-${parEnvironmentSuffix}'

param parSubnets array

@sys.description('Array of DNS Server IP addresses for VNet.')
param parDnsServerIps array = []

@sys.description('IP Address where network traffic should route to leveraged with DNS Proxy.')
param parNextHopIpAddress string = ''

@sys.description('Hub virtual network id is needed to enable peering between hub and spoke')
param parHubNetworkId string

@sys.description('Peering options for hub network')
param parAllowForwardedTraffic bool = true

@sys.description('Peering options for hub network, depends on vpn gateway')
param parAllowGatewayTransit bool = true

@sys.description('Peering options for hub network, depends on vpn gateway')
param parUseRemoteGateways bool = true

@sys.description('Name of Route table to create for the default route of Hub.')
param parSpokeToHubRouteTableName string = 'route-vnet-${parLocation}-${parEnvironmentSuffix}'

param LogAnalyticsWorkspaceId string

param diagnosticLogsRetentionInDays int = 30

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var hubNetworkSubscriptionId = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[2] : ''
var hubNetworkResourceGroup = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[4] : ''
var hubNetworkName = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[8] : ''

// Customer Usage Attribution Id
var varCuaid = '0c428583-f2a1-4448-975c-2d6262fd193a'

// get list of nsgs from subnets object and filter on subnets with nsgs only, used to create nsgs
var nsgList = filter(parSubnets, nsgId => contains(nsgId, 'networkSecurityGroupId'))

var varSubnetMap = map(range(0, length(parSubnets)), i => {
  name: parSubnets[i].name
  ipAddressRange: parSubnets[i].ipAddressRange
  networkSecurityGroupId: contains(parSubnets[i], 'networkSecurityGroupId') ? parSubnets[i].networkSecurityGroupId : ''
  addDefaultRoute: parSubnets[i].addDefaultRoute
})

var varSubnetProperties = [for subnet in varSubnetMap: {
name: subnet.name
properties: {
  addressPrefix: subnet.ipAddressRange
  networkSecurityGroup: (!empty(subnet.networkSecurityGroupId)) ? {
    id: '${resourceGroup().id}/providers/Microsoft.Network/networkSecurityGroups/${subnet.networkSecurityGroupId}'
  } : null
  routeTable: (subnet.addDefaultRoute && !empty(parNextHopIpAddress)) ? {
    id: resSpokeToHubRouteTable.id
  } : null
}
}]

module nsg 'br/modules:microsoft.network.networksecuritygroups:0.4.2051' = [for (nsg, i) in nsgList: {
  name: '${uniqueString(deployment().name, parLocation)}-nsg-${i}'
  params: {
    location: parLocation
    name: nsg.networkSecurityGroupId
    diagnosticWorkspaceId: !empty(LogAnalyticsWorkspaceId) ? LogAnalyticsWorkspaceId : ''
    tags: parTags
  }
}]

resource resSpokeVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  dependsOn: [
    nsg
  ]
  name: parSpokeNetworkName
  location: parLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: parSpokeNetworkAddressPrefixes
    }
    dhcpOptions: {
      dnsServers: parDnsServerIps
    }
    subnets: varSubnetProperties
    enableDdosProtection: (!empty(parDdosProtectionPlanId) ? true : false)
    ddosProtectionPlan: (!empty(parDdosProtectionPlanId) ? true : false) ? {
      id: parDdosProtectionPlanId
    } : null
  }
}


// module modSpokeVirtualNetwork 'br/modules:microsoft.network.virtualnetworks:0.4.0' = {
//   name: '${uniqueString(deployment().name, parLocation)}-vnet'
//   params: {
//     location: parLocation
//     name: parSpokeNetworkName
//     addressPrefixes: parSpokeNetworkAddressPrefixes
//     dnsServers: parDnsServerIps
//     subnets: varSubnetProperties
//     diagnosticWorkspaceId: !empty(LogAnalyticsWorkspaceId) ? LogAnalyticsWorkspaceId : ''
//     diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
//     ddosProtectionPlanId: !empty(parDdosProtectionPlanId) ? parDdosProtectionPlanId : ''
//     tags: parTags
//   }
//   dependsOn: [
//     nsg
//   ]
// }

resource resSpokeToHubRouteTable 'Microsoft.Network/routeTables@2021-08-01' = if (!empty(parNextHopIpAddress)) {
  name: parSpokeToHubRouteTableName
  location: parLocation
  tags: parTags
  properties: {
    routes: [
      {
        name: 'udr-default-to-hub-nva'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: parNextHopIpAddress
        }
      }
    ]
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
}

// Module - Hub to Spoke peering.
module modHubToSpoke 'br/modules:microsoft.network.virtualnetworks.virtualnetworkpeerings:0.4.0' = if (!empty(parHubNetworkId)) {
  scope: resourceGroup(hubNetworkSubscriptionId, hubNetworkResourceGroup)
  name: '${uniqueString(deployment().name, parLocation)}-peering-hub-to-spoke'
  params: {
    localVnetName: hubNetworkName
    remoteVirtualNetworkId: !empty(parHubNetworkId) ? resSpokeVnet.id : ''
    allowForwardedTraffic: parAllowForwardedTraffic
    allowGatewayTransit: parAllowGatewayTransit
  }
}

// Module - Spoke to Hub peering.
module modSpokeToHub 'br/modules:microsoft.network.virtualnetworks.virtualnetworkpeerings:0.4.0' = if (!empty(parHubNetworkId)) {
  name: '${uniqueString(deployment().name, parLocation)}-peering-spoke-to-hub'
  params: {
    localVnetName: resSpokeVnet.name
    remoteVirtualNetworkId: parHubNetworkId
    useRemoteGateways: parUseRemoteGateways
  }
  dependsOn: [
    modHubToSpoke
  ]
}




// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../infra-as-code/bicep/CRML/customerUsageAttribution/cuaIdResourceGroup.bicep' = if (!parTelemetryOptOut) {
  name: 'pid-${varCuaid}-${uniqueString(resourceGroup().id)}'
  params: {}
}

output outSpokeVirtualNetworkName string = resSpokeVnet.name
output outSpokeVirtualNetworkId string = resSpokeVnet.id
