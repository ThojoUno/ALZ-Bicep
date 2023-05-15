


param parLocation string
param parEnvironmentSuffix string = 'hub'
param recoveryServicesVaultName string = 'rsv-${parLocation}-${parEnvironmentSuffix}'

param parRecoveryServicesVault object = {}

param parAzKeyVault object = {}

@maxLength(24)
param azureKeyVaultName string = take('kv-${parLocation}-${uniqueString(subscription().id)}',15)

param LogAnalyticsWorkspaceId string
param parDomainControllers array = []

@sys.description('Hub virtual network id is needed to enable peering between hub and spoke')
param parHubNetworkId string

param parTags object = {}

var hubNetworkSubscriptionId = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[2] : ''
var hubNetworkResourceGroup = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[4] : ''
var hubNetworkName = !empty(parHubNetworkId) ? split(parHubNetworkId,'/')[8] : ''


module modRecoveryServicesVault 'br/modules:microsoft.recoveryservices.vaults:0.4.2053' = if (parRecoveryServicesVault.enableVault) {
  name: '${uniqueString(deployment().name, parLocation)}-identity-rsvault'
  params: {
    location: parLocation
    name: recoveryServicesVaultName
    backupStorageConfig: {
      storageModelType: parRecoveryServicesVault.storageModelType
      crossRegionRestoreFlag: parRecoveryServicesVault.crossRegionRestoreFlag
    }
    diagnosticWorkspaceId: !empty(LogAnalyticsWorkspaceId) ? LogAnalyticsWorkspaceId : ''
    tags: parTags
  }
}

module modAzureKeyVault 'br/modules:microsoft.keyvault.vaults:0.5.2055' = if (parAzKeyVault.enableKeyVault) {
  name: '${uniqueString(deployment().name, parLocation)}-keyvault'
  params: {
    location: parLocation
    name: parAzKeyVault.enableKeyVault ? azureKeyVaultName : ''
    diagnosticWorkspaceId: !empty(LogAnalyticsWorkspaceId) ? LogAnalyticsWorkspaceId : ''
    tags: parTags
  }
}

module modDomainControllers '../../CARML/modules/Compute/virtualMachines/main.bicep' = [for (vm, i) in parDomainControllers: if (vm.enableVm) {
  name: '${uniqueString(deployment().name, parLocation)}-${i}-domainController'
  dependsOn: [
    modRecoveryServicesVault
  ]
  params: {
    location: parLocation
    name: vm.vmName
    adminUsername: vm.adminUser
    adminPassword: vm.adminPassword
    imageReference: vm.imageReference
    encryptionAtHost: false
    systemAssignedIdentity: true
    nicConfigurations: [
      {
        deleteOption: vm.nicConfig.deleteOption
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: '/subscriptions/${hubNetworkSubscriptionId}/resourceGroups/${hubNetworkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${hubNetworkName}/subnets/${vm.subnetName}'
          }
        ]
        nicSuffix: '-nic-01'
        enableAcceleratedNetworking: vm.nicConfig.enableAcceleratedNetworking
      }
    ]
    osDisk: vm.osDisk
    osType: vm.ostype
    vmSize: vm.vmSize
    diagnosticWorkspaceId: (vm.enableDiagnostics && !empty(LogAnalyticsWorkspaceId)) ? LogAnalyticsWorkspaceId : ''
    enableAutomaticUpdates: true
    extensionAntiMalwareConfig: {
      enabled: true
      settings: {
        AntimalwareEnabled: 'true'
        Exclusions: {}
        RealtimeProtectionEnabled: 'true'
        ScheduledScanSettings: {
          day: '7'
          isEnabled: 'true'
          scanType: 'Quick'
          time: '120'
        }
      }
      tags: parTags
    }
    configurationProfile: '/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesProduction'
    backupPolicyName: 'DefaultPolicy'
    backupVaultName: !empty(recoveryServicesVaultName) ? modRecoveryServicesVault.outputs.name : ''
    backupVaultResourceGroup: !empty(recoveryServicesVaultName) ? modRecoveryServicesVault.outputs.resourceGroupName : ''
  }
}]
