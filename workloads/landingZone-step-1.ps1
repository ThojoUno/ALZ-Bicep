

$UPSTREAM_RELEASE_VERSION="v0.14.0"

#KeyPointCU
$TenantId = 'f5df4ba2-d9cb-4035-8bca-00596721ff73'

$HubSubId = 'b460a424-adfe-4d8e-90dd-5da3db14fdca'
$SpokeSubId = 'd43be967-fc54-4957-bcfd-e33319a08da1'

Connect-AzAccount -TenantId $tenantId

Set-AzContext -Subscription $HubSubId

Get-AzContext

### Initial prerequisites, need permissions to modify management group structure
#get object Id of the current user (that is used above)
$user = Get-AzADUser -SignedIn               #-Mail (Get-AzContext).Account.Id

#assign Owner role at Tenant root scope ("/") as a User Access Administrator to current user
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id

$Location = 'westus2'
$ManagementGroupPrefix = 'alz'

$PlatformSubscriptionId = 'b460a424-adfe-4d8e-90dd-5da3db14fdca'
$ManagementSubscriptionId = 'b460a424-adfe-4d8e-90dd-5da3db14fdca'
$ManagementResourceGroup  =  "rg-$Location-mgmt-hub"
$ConnectivitySubscriptionId = 'b460a424-adfe-4d8e-90dd-5da3db14fdca'
$ConnectivityResourceGroup = "rg-$Location-network-hub"
$ConnectivityNetworkName   = "vnet-$Location-hub"
$LogAnalyticsWorkspaceName = "log-$Location-hub"
$CorpLzSubscriptionId = 'd43be967-fc54-4957-bcfd-e33319a08da1'
$LogAnalyticsWorkspaceId = "/subscriptions/$ManagementSubscriptionId/resourcegroups/$ManagementResourceGroup/providers/microsoft.operationalinsights/workspaces/$LogAnalyticsWorkspaceName"
$SpokeNetworkResourceGroupName = "rg-$Location-network-prod"
$IdentitySubscriptionId    = 'b460a424-adfe-4d8e-90dd-5da3db14fdca'
$IdentityResourceGroup     = "rg-$Location-identity-hub"

# Create management group structure (Workflow #1)
$mgmtGrpObject = @{
  DeploymentName                        = 'alz-MGDeployment-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                              = $Location
  TemplateFile                          = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/managementGroups/managementGroups.bicep"
  TemplateParameterFile                 = 'config/custom-parameters/managementGroups.parameters.all.json'
  Verbose                               = $true
}

New-AzTenantDeployment @mgmtGrpObject


# Deploy Custom Policy Definitions (Workflow #1)
$policyDefsMgObject = @{
  DeploymentName                        = 'alz-PolicyDefsDeployment-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                              = $Location
  ManagementGroupId                     = $ManagementGroupPrefix
  TemplateFile                          = "upstream-releases/$UPSTREAM_RELEASE_VERSIONinfra-as-code/bicep/modules/policy/definitions/customPolicyDefinitions.bicep"
  TemplateParameterFile                 = 'config/custom-parameters/customPolicyDefinitions.parameters.all.json'
  Verbose                               = $true
}

New-AzManagementGroupDeployment @policyDefsMgObject

# Deploy Custom Role Definitions (Workflow #1)
$customRolesMgObject = @{
  DeploymentName                        = 'alz-CustomRoleDefsDeployment-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                              = $Location
  ManagementGroupId                     = $ManagementGroupPrefix
  TemplateFile                          = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep"
  TemplateParameterFile                 = 'config/custom-parameters/customRoleDefinitions.parameters.all.json'
  Verbose                               = $true
}

New-AzManagementGroupDeployment @customRolesMgObject

# Deploy Logging Resource Group (Workflow #1)
$loggingRgObject = @{
  DeploymentName              = 'alz-LoggingAndSentinelRGDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                    = $Location
  TemplateFile                = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep"
  parResourceGroupName        = $ManagementResourceGroup
  parLocation                 = $Location
  parTags                     = @{'DeployedBy'='Lunavi'; 'Subscription'='Platform'; 'Environment'='hub'}
  Verbose                     = $true
}

Set-AzContext -Subscription $ManagementSubscriptionId
New-AzSubscriptionDeployment @loggingRgObject

# Deploy logging (Workflow #1)
$loggingObject = @{
  DeploymentName              = 'alz-LoggingDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName           = $ManagementResourceGroup
  TemplateFile                = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/logging/logging.bicep"
  TemplateParameterFile       = 'config/custom-parameters/logging.parameters.all.json'
  parLogAnalyticsWorkspaceName = $LogAnalyticsWorkspaceName
  parLogAnalyticsWorkspaceLocation = $Location
  parAutomationAccountName    = "aa-$Location-hub"
  Verbose                     = $true
}

Set-AzContext -Subscription $HubSubId
New-AzResourceGroupDeployment @loggingObject

# Management group Diagnostic settings (Workflow #1)
$mgDiagObject = @{
  DeploymentName        = 'alz-MGDiagnosticSettings-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = $Location
  ManagementGroupId     = $ManagementGroupPrefix
  TemplateFile          = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code\bicep\orchestration\mgDiagSettingsAll\mgDiagSettingsAll.bicep"
  TemplateParameterFile = 'config\custom-parameters\mgDiagSettingsAll.parameters.all.json'
  parTopLevelManagementGroupPrefix = $ManagementGroupPrefix
  parLogAnalyticsWorkspaceResourceId = $LogAnalyticsWorkspaceId
  Verbose               = $true
}

New-AzManagementGroupDeployment @mgDiagObject

#Deploy Default Policy Assignments (Workflow #2)
#TODO - change child platform assignments to resource groups

$defPolicyObject = @{
  DeploymentName        = 'alz-PolicyAssignmentsDeployment-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = $Location
  ManagementGroupId     = $ManagementGroupPrefix
  TemplateFile          = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.bicep"
  TemplateParameterFile = 'config\custom-parameters\alzDefaultPolicyAssignments.parameters.all.json'
  parLogAnalyticsWorkSpaceAndAutomationAccountLocation = $Location
  parLogAnalyticsWorkspaceResourceId = $LogAnalyticsWorkspaceId
  parLogAnalyticsWorkspaceLogRetentionInDays = 30
  parAutomationAccountName = "aa-$Location-hub"
  parPrivateDnsResourceGroupId = "/subscriptions/$ConnectivitySubscriptionId/resourceGroups/rg-$Location-network-hub"
  Verbose               = $true
}

New-AzManagementGroupDeployment @defPolicyObject

#Deploy Subscription Placement (Workflow #3)
$subObject = @{
  DeploymentName        = 'alz-SubPlacementAll-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = $Location
  TemplateFile          = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/orchestration/subPlacementAll/subPlacementAll.bicep"
  ManagementGroupId     = $ManagementGroupPrefix
  parTopLevelManagementGroupPrefix = $ManagementGroupPrefix
  parPlatformMgSubs     = $PlatformSubscriptionId
  parLandingZonesCorpMgSubs = $CorpLzSubscriptionId
  Verbose               = $true
}

New-AzManagementGroupDeployment @subObject

#Deploy Hub Networking Resource Group (Workflow #4a)
$hubNetRgObject = @{
  DeploymentName              = 'alz-HubnetworklRGDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                    = $Location
  TemplateFile                = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep"
  parResourceGroupName        = $ConnectivityResourceGroup
  parLocation                 = $Location
  parTags                     = @{'DeployedBy'='Lunavi'; 'Subscription'='Platform'; 'Environment'='hub'}
  Verbose                     = $true
}

Set-AzContext -Subscription $ConnectivitySubscriptionId
New-AzSubscriptionDeployment @hubNetRgObject

Get-AzResourceProvider -ListAvailable | Where-Object RegistrationState -eq "Registered" | Select-Object ProviderNamespace, RegistrationState | Sort-Object ProviderNamespace
Register-AzResourceProvider -ProviderNamespace Microsoft.Network
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute

#Deploy Hub Network (Workflow #4a)
# todo - route table logic needs work
# todo - transfer to bicep registry for modules
$hubNetworkObject = @{
  DeploymentName        = 'alz-Hub-and-SpokeDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = $ConnectivityResourceGroup
  TemplateFile          = 'config/custom-modules/hubNetworking.bicep'
  TemplateParameterFile = 'workloads/keypointcu/hubNetworking.parameters.all.json'
  parLocation           = $Location
  parTags               = @{'DeployedBy'='Lunavi'; 'Subscription'='Platform'; 'Environment'='hub'}
  parAzFirewallTier     = 'Standard'
  Verbose               = $true
}

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
New-AzResourceGroupDeployment @hubNetworkObject


#Deploy Role Assignments
#TODO
scope: managementgroup
          managementGroupId: ${{ env.RoleAssignmentManagementGroupId }}
          region: ${{ env.Location }}
          template: infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep
          parameters: infra-as-code/bicep/modules/roleAssignments/parameters/roleAssignmentManagementGroup.servicePrincipal.parameters.all.json

#Deploy Spoke Networking Resource Group
$spokeNetRgObject = @{
  DeploymentName              = 'alz-HubnetworklRGDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                    = $Location
  TemplateFile                = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep"
  parResourceGroupName        = $SpokeNetworkResourceGroupName
  parLocation                 = $Location
  parTags                     = @{'DeployedBy'='Lunavi'; 'Subscription'='Prod'; 'Environment'='Prod'}
  Verbose                     = $true
}

Set-AzContext -Subscription $CorpLzSubscriptionId
New-AzSubscriptionDeployment @spokeNetRgObject


#Deploy Spoke Network
$spokeNetworkObject = @{
  DeploymentName        = 'alz-SpokeDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = $SpokeNetworkResourceGroupName
  TemplateFile          = 'config/custom-modules/spokeNetworking.bicep'
  TemplateParameterFile = 'workloads/keypointcu/spokeNetworking.parameters.all.json'
  parLocation           = $Location
  parHubNetworkId       = "/subscriptions/$ConnectivitySubscriptionId/resourceGroups/$ConnectivityResourceGroup/providers/Microsoft.Network/virtualNetworks/$ConnectivityNetworkName"
  parAllowForwardedTraffic = $true
  parAllowGatewayTransit = $true
  parUseRemoteGateways  = $true
  LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId
  parTags               = @{'DeployedBy'='Lunavi'; 'Subscription'='Prod'; 'Environment'='Prod'}
  Verbose               = $true
}

Select-AzSubscription -SubscriptionId $CorpLzSubscriptionId

Register-AzResourceProvider -ProviderNamespace Microsoft.Network

New-AzResourceGroupDeployment @spokeNetworkObject

#Deploy identity resource group
$identityRgObject = @{
  DeploymentName              = 'alz-IdentityRGDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                    = $Location
  TemplateFile                = "upstream-releases/$UPSTREAM_RELEASE_VERSION/infra-as-code/bicep/modules/resourceGroup/resourceGroup.bicep"
  parResourceGroupName        = $IdentityResourceGroup
  parLocation                 = $Location
  parTags                     = @{'DeployedBy'='Lunavi'; 'Subscription'='Platform'; 'Environment'='Identity'}
  Verbose                     = $true
}

Set-AzContext -Subscription $IdentitySubscriptionId
New-AzSubscriptionDeployment @identityRgObject

#Deploy Identity resources
$hubIdentityObject = @{
  DeploymentName        = 'alz-HubIdentityDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = $IdentityResourceGroup
  TemplateFile          = 'config/custom-modules/hubIdentity.bicep'
  TemplateParameterFile = 'workloads/keypointcu/hubIdentity.parameters.json'
  parLocation           = $Location
  parHubNetworkId       = "/subscriptions/$ConnectivitySubscriptionId/resourceGroups/$ConnectivityResourceGroup/providers/Microsoft.Network/virtualNetworks/$ConnectivityNetworkName"
  LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId
  parTags               = @{'DeployedBy'='Lunavi'; 'Subscription'='Platform'; 'Environment'='Identity'}
  Verbose               = $true
}

Select-AzSubscription -SubscriptionId $IdentitySubscriptionId

Register-AzResourceProvider -ProviderNamespace Microsoft.Compute

New-AzResourceGroupDeployment @hubIdentityObject

