metadata name = 'ALZ Bicep - Hub Networking Module'
metadata description = 'ALZ Bicep Module used to set up Hub Networking'

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Prefix value which will be appended to all resource names.')
param parEnvironmentSuffix string = 'hub'

@sys.description('Prefix Used for Hub Network.')
param parHubNetworkName string = 'vnet-${parLocation}-${parEnvironmentSuffix}'

param parHubRouteTableName string = 'route-${parHubNetworkName}'

@sys.description('The IP address range for all virtual networks to use.')
param parHubNetworkAddressPrefixes array = [
  '10.10.0.0/16'
]

@sys.description('The IP address range for all virtual networks to use.')

@sys.description('The name, IP address range, network security group and route table for each subnet in the virtual networks.')
param parSubnets array = [
  {
    name: 'AzureBastionSubnet'
    ipAddressRange: '10.10.15.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'GatewaySubnet'
    ipAddressRange: '10.10.252.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'AzureFirewallSubnet'
    ipAddressRange: '10.10.254.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'AzureFirewallManagementSubnet'
    ipAddressRange: '10.10.253.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
]

@sys.description('Array of DNS Server IP addresses for VNet.')
param parDnsServerIps array = []

@sys.description('Public IP Address SKU.')
@allowed([
  'Basic'
  'Standard'
])
param parPublicIpSku string = 'Standard'

@sys.description('Optional Prefix for Public IPs. Include a succedent dash if required. Example: prefix-')
param parPublicIpPrefix string = 'pip-'

@sys.description('Optional Suffix for Public IPs. Include a preceding dash if required. Example: -suffix')
param parPublicIpSuffix string = ''

@sys.description('Switch to enable/disable Azure Bastion deployment. Default: true')
param parAzBastionEnabled bool = true

@sys.description('Names Associated with Bastion Service.')
param parAzBastionName string = 'bastion-${parLocation}-${parEnvironmentSuffix}'

param parAzBastionPipName string = '${parPublicIpPrefix}${parAzBastionName}${parPublicIpSuffix}'

@sys.description('Azure Bastion SKU or Tier to deploy.  Currently two options exist Basic and Standard.')
param parAzBastionSku string = 'Standard'

@sys.description('NSG Name for Azure Bastion Subnet NSG.')
param parAzBastionNsgName string = 'nsg-AzureBastionSubnet'

@sys.description('Switch to enable/disable DDoS Network Protection deployment.')
param parDdosEnabled bool = false

@sys.description('DDoS Plan Name.')
param parDdosPlanName string = 'ddos-plan-${parLocation}-${parEnvironmentSuffix}'

@sys.description('Switch to enable/disable Azure Firewall deployment.')
param parAzFirewallEnabled bool = true

@sys.description('Azure Firewall Name.')
param parAzFirewallName string = 'azfw-${parLocation}-${parEnvironmentSuffix}'

@sys.description('Azure Firewall Policies Name.')
param parAzFirewallPoliciesName string = 'azfwpolicy-${parLocation}-${parEnvironmentSuffix}'

param threatIntelMode string = 'Alert'

// NEED TO UPDATE CARML FIREWALL MODULE TO ACCEPT BASIC TIER
@sys.description('Azure Firewall Tier associated with the Firewall to deploy.')
@allowed([
  'Standard'
  'Premium'
])
param parAzFirewallTier string = 'Standard'

/* @allowed([
  'Basic'
  'Standard'
  'Premium'
]) */


// @allowed([
//   '1'
//   '2'
//   '3'
// ])
@sys.description('Availability Zones to deploy the Azure Firewall across. Region must support Availability Zones to use. If it does not then leave empty.')
param parAzFirewallAvailabilityZones array = []

@allowed([
  '1'
  '2'
  '3'
])
@sys.description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param parAzErGatewayAvailabilityZones array = []

// @allowed([
//   '1'
//   '2'
//   '3'
// ])
@sys.description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param parAzVpnGatewayAvailabilityZones array = []

@sys.description('Switch to enable/disable Azure Firewall DNS Proxy.')
param parAzFirewallDnsProxyEnabled bool = true

@sys.description('Switch to enable/disable BGP Propagation on route table.')
param parDisableBgpRoutePropagation bool = false

@sys.description('Switch to enable/disable Private DNS Zones deployment.')
param parPrivateDnsZonesEnabled bool = true

@sys.description('Resource Group Name for Private DNS Zones.')
param parPrivateDnsZonesResourceGroup string = resourceGroup().name

@sys.description('Array of DNS Zones to provision in Hub Virtual Network. Default: All known Azure Private DNS Zones')
param parPrivateDnsZones array = [
  'privatelink.${toLower(parLocation)}.azmk8s.io'
  'privatelink.${toLower(parLocation)}.batch.azure.com'
  'privatelink.${toLower(parLocation)}.kusto.windows.net'
  'privatelink.adf.azure.com'
  'privatelink.afs.azure.net'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.analysis.windows.net'
  'privatelink.api.azureml.ms'
  'privatelink.azconfig.io'
  'privatelink.azure-api.net'
  'privatelink.azure-automation.net'
  'privatelink.azurecr.io'
  'privatelink.azure-devices.net'
  'privatelink.azure-devices-provisioning.net'
  'privatelink.azurehdinsight.net'
  'privatelink.azurehealthcareapis.com'
  'privatelink.azurestaticapps.net'
  'privatelink.azuresynapse.net'
  'privatelink.azurewebsites.net'
  'privatelink.batch.azure.com'
  'privatelink.blob.core.windows.net'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.database.windows.net'
  'privatelink.datafactory.azure.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.dicom.azurehealthcareapis.com'
  'privatelink.digitaltwins.azure.net'
  'privatelink.directline.botframework.com'
  'privatelink.documents.azure.com'
  'privatelink.eventgrid.azure.net'
  'privatelink.file.core.windows.net'
  'privatelink.gremlin.cosmos.azure.com'
  'privatelink.guestconfiguration.azure.com'
  'privatelink.his.arc.azure.com'
  'privatelink.kubernetesconfiguration.azure.com'
  'privatelink.managedhsm.azure.net'
  'privatelink.mariadb.database.azure.com'
  'privatelink.media.azure.net'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.monitor.azure.com'
  'privatelink.mysql.database.azure.com'
  'privatelink.notebooks.azure.net'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.pbidedicated.windows.net'
  'privatelink.postgres.database.azure.com'
  'privatelink.prod.migration.windowsazure.com'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink.queue.core.windows.net'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.search.windows.net'
  'privatelink.service.signalr.net'
  'privatelink.servicebus.windows.net'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.sql.azuresynapse.net'
  'privatelink.table.core.windows.net'
  'privatelink.table.cosmos.azure.com'
  'privatelink.tip1.powerquery.microsoft.com'
  'privatelink.token.botframework.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.web.core.windows.net'
  'privatelink.webpubsub.azure.com'
]

//ASN must be 65515 if deploying VPN & ER for co-existence to work: https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-coexist-resource-manager#limits-and-limitations
@sys.description('''Configuration for VPN virtual network gateway to be deployed. If a VPN virtual network gateway is not desired an empty object should be used as the input parameter in the parameter file, i.e.
"parVpnGatewayConfig": {
  "value": {}
}''')
param parVpnGatewayConfig object = {
  name: 'vpn-${parLocation}-${parEnvironmentSuffix}'
  gatewayType: 'Vpn'
  sku: 'VpnGw1'
  vpnType: 'RouteBased'
  generation: 'Generation1'
  enableBgp: false
  activeActive: false
  enableBgpRouteTranslationForNat: false
  enableDnsForwarding: false
  bgpPeeringAddress: ''
  bgpsettings: {
    asn: 65515
    bgpPeeringAddress: ''
    peerWeight: 5
  }
}

@sys.description('''Configuration for ExpressRoute virtual network gateway to be deployed. If a ExpressRoute virtual network gateway is not desired an empty object should be used as the input parameter in the parameter file, i.e.
"parExpressRouteGatewayConfig": {
  "value": {}
}''')
param parExpressRouteGatewayConfig object = {
  name: 'ergw-${parLocation}-${parEnvironmentSuffix}'
  gatewayType: 'ExpressRoute'
  sku: 'ErGw1AZ'
  vpnType: 'RouteBased'
  vpnGatewayGeneration: 'None'
  enableBgp: false
  activeActive: false
  enableBgpRouteTranslationForNat: false
  enableDnsForwarding: false
  bgpPeeringAddress: ''
  bgpsettings: {
    asn: '65515'
    bgpPeeringAddress: ''
    peerWeight: '5'
  }
}

param diagnosticLogsRetentionInDays int = 7

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

@sys.description('Define outbound destination ports or ranges for SSH or RDP that you want to access from Azure Bastion.')
param parBastionOutboundSshRdpPorts array = [ '22', '3389' ]

var varSubnetMap = map(range(0, length(parSubnets)), i => {
  name: parSubnets[i].name
  ipAddressRange: parSubnets[i].ipAddressRange
  networkSecurityGroupId: contains(parSubnets[i], 'networkSecurityGroupId') ? parSubnets[i].networkSecurityGroupId : ''
  routeTableId: contains(parSubnets[i], 'routeTableId') ? parSubnets[i].routeTableId : ''
})

var varSubnetProperties = [for subnet in varSubnetMap: {
name: subnet.name
properties: {
  addressPrefix: subnet.ipAddressRange
  networkSecurityGroup: (!empty(subnet.networkSecurityGroupId)) ? {
    id: '${resourceGroup().id}/providers/Microsoft.Network/networkSecurityGroups/${subnet.networkSecurityGroupId}'
  } : null
  routeTable: (!empty(subnet.routeTableId)) ? {
    id: '${resourceGroup().id}/providers/Microsoft.Network/routeTables/${subnet.routeTableId}'
  } : null
}
}]

var varVpnGwConfig = ((!empty(parVpnGatewayConfig)) ? parVpnGatewayConfig : json('{"name": "noconfigVpn"}'))

var varErGwConfig = ((!empty(parExpressRouteGatewayConfig)) ? parExpressRouteGatewayConfig : json('{"name": "noconfigEr"}'))

var varGwConfig = [
  varVpnGwConfig
  varErGwConfig
]

// Customer Usage Attribution Id Telemetry
var varCuaid = '2686e846-5fdc-4d4f-b533-16dcb09d6e6c'

// ZTN Telemetry
var varZtnP1CuaId = '3ab23b1e-c5c5-42d4-b163-1402384ba2db'
var varZtnP1Trigger = (parDdosEnabled && parAzFirewallEnabled && (parAzFirewallTier == 'Premium')) ? true : false

var nsgList = filter(parSubnets, nsg => !empty(nsg.networkSecurityGroupId))

resource resLogWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup('rg-${parLocation}-mgmt-${parEnvironmentSuffix}')
  name: 'log-${parLocation}-${parEnvironmentSuffix}'
}

module moduleNsg 'br/modules:microsoft.network.networksecuritygroups:0.4.2051' = [for (nsg, i) in nsgList: {
  name: '${uniqueString(deployment().name, parLocation)}-nsg-${i}'
  params: {
    location: parLocation
    name: (nsg.networkSecurityGroupId != null) ? nsg.networkSecurityGroupId : ''
    diagnosticWorkspaceId: resLogWorkspace.id
    tags: parTags
  }
}]

//DDos Protection plan will only be enabled if parDdosEnabled is true.
resource resDdosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2021-08-01' = if (parDdosEnabled) {
  name: parDdosPlanName
  location: parLocation
  tags: parTags
}

module moduleUdr 'br/modules:microsoft.network.routetables:0.4.2049' = if (parAzFirewallEnabled) {
  name: '${uniqueString(deployment().name, parLocation)}-udr'
  params: {
    location: parLocation
    name: parHubRouteTableName
    routes: []
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
    tags: parTags
  }
}

resource resHubVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  dependsOn: [
    resBastionNsg
    moduleNsg
  ]
  name: parHubNetworkName
  location: parLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: parHubNetworkAddressPrefixes
    }
    dhcpOptions: {
      dnsServers: parDnsServerIps
    }
    subnets: varSubnetProperties
    enableDdosProtection: parDdosEnabled
    ddosProtectionPlan: (parDdosEnabled) ? {
      id: resDdosProtectionPlan.id
    } : null
  }
}


module modBastionHost 'br/modules:microsoft.network.bastionhosts:0.4.2057' = if (parAzBastionEnabled) {
  name: '${uniqueString(deployment().name, parLocation)}-bastion'
  params: {
    location: parLocation
    name: parAzBastionName
    vNetId: resHubVnet.id
    skuName: parAzBastionSku
    publicIPAddressObject: { name: parAzBastionPipName }
    diagnosticWorkspaceId: resLogWorkspace.id
    tags: parTags
  }
}

resource resBastionNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = if (parAzBastionEnabled) {
  name: parAzBastionNsgName
  location: parLocation
  tags: parTags
  properties: {
    securityRules: [
      // Inbound Rules
      {
        name: 'AllowHttpsInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 120
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 130
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 140
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 150
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 4096
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
      // Outbound Rules
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 100
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: parBastionOutboundSshRdpPorts
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 110
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 120
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 130
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          access: 'Deny'
          direction: 'Outbound'
          priority: 4096
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module modVpnGateway 'br/modules:microsoft.network.virtualnetworkgateways:0.4.2060' = [for (gateway, i) in varGwConfig: if ((gateway.name != 'noconfigVpn') && (gateway.name != 'noconfigEr')) {
  name: '${uniqueString(deployment().name, parLocation)}-vpnGateway-${gateway.name}'
  params: {
    location: parLocation
    gatewayType: gateway.gatewayType
    vpnGatewayGeneration: (gateway.gatewayType == 'VPN') ? gateway.generation : 'None'
    vpnType: gateway.vpnType
    name: gateway.name
    skuName: gateway.sku
    activeActive: gateway.activeActive
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    vNetResourceId: resHubVnet.id
    gatewayPipName: '${parPublicIpPrefix}${gateway.name}${parPublicIpSuffix}'
    diagnosticWorkspaceId: resLogWorkspace.id
    tags: parTags
  }
}]

module modAzureFirewall 'br/modules:microsoft.network.azurefirewalls:0.4.2058' = if (parAzFirewallEnabled) {
  name: '${uniqueString(deployment().name, parLocation)}-azFirewall'
  params: {
    location: parLocation
    name: parAzFirewallName
    vNetId: resHubVnet.id
    azureSkuTier: parAzFirewallTier
    firewallPolicyId: parAzFirewallEnabled ? modAzureFirewallPolicy.outputs.resourceId : ''
    publicIPAddressObject: { name: '${parPublicIpPrefix}${parAzFirewallName}${parPublicIpSuffix}' }
    threatIntelMode: threatIntelMode
    diagnosticWorkspaceId: resLogWorkspace.id
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    zones: parAzFirewallAvailabilityZones
    tags: parTags
  }
}

module modAzureFirewallPolicy 'br/modules:microsoft.network.firewallpolicies:0.4.2059' = if (parAzFirewallEnabled) {
  name: '${uniqueString(deployment().name, parLocation)}-azFirewall-policy'
  params: {
    location: parLocation
    name: parAzFirewallPoliciesName
    tier: parAzFirewallTier
  }
}

module modUdr 'br/modules:microsoft.network.routetables:0.4.2049' = if (parAzFirewallEnabled) {
  name: '${uniqueString(deployment().name, parLocation)}-udr-to-firewall'
  params: {
    name: parHubRouteTableName
    routes: [
      {
        name: 'to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: parAzFirewallEnabled ? modAzureFirewall.outputs.privateIp : ''
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module modPrivateDnsZones '../../infra-as-code/bicep/modules/privateDnsZones/privateDnsZones.bicep' = if (parPrivateDnsZonesEnabled) {
  name: 'deploy-Private-DNS-Zones'
  scope: resourceGroup(parPrivateDnsZonesResourceGroup)
  params: {
    parLocation: parLocation
    parTags: parTags
    parVirtualNetworkIdToLink: resHubVnet.id
    parPrivateDnsZones: parPrivateDnsZones
    parTelemetryOptOut: parTelemetryOptOut
  }
}

// Optional Deployments for Customer Usage Attribution
module modCustomerUsageAttribution '../../infra-as-code/bicep/CRML/customerUsageAttribution/cuaIdResourceGroup.bicep' = if (!parTelemetryOptOut) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varCuaid}-${uniqueString(resourceGroup().location)}'
  params: {}
}

module modCustomerUsageAttributionZtnP1 '../../infra-as-code/bicep/CRML/customerUsageAttribution/cuaIdResourceGroup.bicep' = if (!parTelemetryOptOut && varZtnP1Trigger) {
  #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  name: 'pid-${varZtnP1CuaId}-${uniqueString(resourceGroup().location)}'
  params: {}
}

//If Azure Firewall is enabled we will deploy a RouteTable to redirect Traffic to the Firewall.
output outAzFirewallPrivateIp string = parAzFirewallEnabled ? modAzureFirewall.outputs.privateIp : ''

//If Azure Firewall is enabled we will deploy a RouteTable to redirect Traffic to the Firewall.
output outAzFirewallName string = parAzFirewallEnabled ? parAzFirewallName : ''

output outPrivateDnsZones array = (parPrivateDnsZonesEnabled ? modPrivateDnsZones.outputs.outPrivateDnsZones : [])
output outPrivateDnsZonesNames array = (parPrivateDnsZonesEnabled ? modPrivateDnsZones.outputs.outPrivateDnsZonesNames : [])

output outDdosPlanResourceId string = resDdosProtectionPlan.id
output outHubVirtualNetworkName string = resHubVnet.name
output outHubVirtualNetworkId string = resHubVnet.id

output outNsgList array = nsgList
