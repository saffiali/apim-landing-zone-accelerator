//
//   ***@microsoft.com, 2021
//
// Deploy as
//
// # Script start
//
// $RESOURCE_GROUP = "rgAPIMCSBackend"
// $LOCATION = "westeurope"
// $BICEP_FILE="networking.bicep"
//
// # delete a deployment
//
// az deployment group  delete --name testnetworkingdeployment -g $RESOURCE_GROUP 
// 
// # deploy the bicep file directly
//
// az deployment group create --name testnetworkingdeployment --template-file $BICEP_FILE --parameters parameters.json -g $RESOURCE_GROUP -o json
// 
// # Script end


// Parameters
@description('A short name for the workload being deployed')
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param deploymentEnvironment string

param apimCSVNetNameAddressPrefix string = '10.2.0.0/16'

param bastionAddressPrefix string = '10.2.1.0/24'
param devOpsNameAddressPrefix string = '10.2.2.0/24'
param jumpBoxAddressPrefix string = '10.2.3.0/24'
param appGatewayAddressPrefix string = '10.2.4.0/24'
param privateEndpointAddressPrefix string = '10.2.5.0/24'
param backEndAddressPrefix string = '10.2.6.0/24'
param apimAddressPrefix string = '10.2.7.0/24'

/*
@description('A short name for the PL that will be created between Funcs')
param privateLinkName string = 'myPL'

@description('Func id for PL to create')
param functionId string = '123131'
*/

// Variables
var owner = 'APIM Const Set'
param location string = resourceGroup().location
//var location = resourceGroup().location


var apimCSVNetName = 'vnet-apim-cs-${workloadName}-${deploymentEnvironment}-${location}'

var bastionSubnetName = 'AzureBastionSubnet' // Azure Bastion subnet must have AzureBastionSubnet name, not 'snet-bast-${workloadName}-${deploymentEnvironment}-${location}'
var devOpsSubnetName = 'snet-devops-${workloadName}-${deploymentEnvironment}-${location}'
var jumpBoxSubnetName = 'snet-jbox-${workloadName}-${deploymentEnvironment}-${location}-001'
var appGatewaySubnetName = 'snet-apgw-${workloadName}-${deploymentEnvironment}-${location}-001'
var privateEndpointSubnetName = 'snet-prep-${workloadName}-${deploymentEnvironment}-${location}-001'
var backEndSubnetName = 'snet-bcke-${workloadName}-${deploymentEnvironment}-${location}-001'
var apimSubnetName = 'snet-apim-${workloadName}-${deploymentEnvironment}-${location}-001'
var bastionName = 'bastion-${workloadName}-${deploymentEnvironment}-${location}'	
var bastionIPConfigName = 'bastionipcfg-${workloadName}-${deploymentEnvironment}-${location}'

var bastionSNNSG = 'nsg-bast-${workloadName}-${deploymentEnvironment}-${location}'
var devOpsSNNSG = 'nsg-devops-${workloadName}-${deploymentEnvironment}-${location}'
var jumpBoxSNNSG = 'nsg-jbox-${workloadName}-${deploymentEnvironment}-${location}'
var appGatewaySNNSG = 'nsg-apgw-${workloadName}-${deploymentEnvironment}-${location}'
var privateEndpointSNNSG = 'nsg-prep-${workloadName}-${deploymentEnvironment}-${location}'
var backEndSNNSG = 'nsg-bcke-${workloadName}-${deploymentEnvironment}-${location}'
var apimSNNSG = 'nsg-apim-${workloadName}-${deploymentEnvironment}-${location}'

var publicIPAddressName = 'pip-apimcs-${workloadName}-${deploymentEnvironment}-${location}' // 'publicIp'
var publicIPAddressNameBastion = 'pip-bastion-${workloadName}-${deploymentEnvironment}-${location}'

// Resources - VNet - SubNets
resource vnetApimCs 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: apimCSVNetName
  location: location
  tags: {
    Owner: owner
    // CostCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        apimCSVNetNameAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionAddressPrefix
          networkSecurityGroup: {
            id: bastionNSG.id
          }
        }
      }
      {
        name: devOpsSubnetName
        properties: {
          addressPrefix: devOpsNameAddressPrefix
          networkSecurityGroup: {
            id: devOpsNSG.id
          }
        }
      }
      {
        name: jumpBoxSubnetName
        properties: {
          addressPrefix: jumpBoxAddressPrefix
          networkSecurityGroup: {
            id: jumpBoxNSG.id
          }
        }
        
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewayAddressPrefix
          networkSecurityGroup: {
            id: appGatewayNSG.id
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointNSG.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: backEndSubnetName
        properties: {
          addressPrefix: backEndAddressPrefix
          networkSecurityGroup: {
            id: backEndNSG.id
          }
        }
      }
      {
        name: apimSubnetName
        properties: {
          addressPrefix: apimAddressPrefix
          networkSecurityGroup: {
            id: apimNSG.id
          }
        }
      }
    ]
  }
}

// Network Security Groups (NSG)

// Bastion NSG must have mininal set of rules below
resource bastionNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: bastionSNNSG
  location: location
  properties: {
    securityRules: [
/* 
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          }
        } 
*/
        {
          name: 'AllowHttpsInbound'
          properties: {
            priority: 120
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
          }              
        }
        {
          name: 'AllowGatewayManagerInbound'
          properties: {
            priority: 130
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
          }              
        }
        {
            name: 'AllowAzureLoadBalancerInbound'
            properties: {
              priority: 140
              protocol: 'Tcp'
              destinationPortRange: '443'
              access: 'Allow'
              direction: 'Inbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'AzureLoadBalancer'
              destinationAddressPrefix: '*'
            }         
          }     
          {
              name: 'AllowBastionHostCommunicationInbound'
              properties: {
                priority: 150
                protocol: '*'
                destinationPortRanges:[
                  '8080'
                  '5701'                
                ] 
                access: 'Allow'
                direction: 'Inbound'
                sourcePortRange: '*'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationAddressPrefix: 'VirtualNetwork'
              }              
          }                    
          {
            name: 'DenyAllInbound'
            properties: {
              priority: 4096
              protocol: '*'
              destinationPortRange:'*'
              access: 'Deny'
              direction: 'Inbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: '*'
            }             
          } 
          {
            name: 'AllowSshRdpOutbound'
            properties: {
              priority: 100
              protocol: '*'
              destinationPortRanges:[
                '22'
                '3389'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }       
          {
            name: 'AllowAzureCloudOutbound'
            properties: {
              priority: 110
              protocol: 'Tcp'
              destinationPortRange:'443'              
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'AzureCloud'
            }              
          }                                                         
          {
            name: 'AllowBastionCommunication'
            properties: {
              priority: 120
              protocol: '*'
              destinationPortRanges: [  
                '8080'
                '5701'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }                     
          {
            name: 'AllowGetSessionInformation'
            properties: {
              priority: 130
              protocol: '*'
              destinationPortRange: '80'
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'Internet'
            }              
          }                                                                   
    ]
  }
}

resource devOpsNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: devOpsSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource jumpBoxNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: jumpBoxSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource appGatewayNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: appGatewaySNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HealthProbes'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_TLS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAll'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}
resource privateEndpointNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: privateEndpointSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource backEndNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: backEndSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource apimNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: apimSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'apim-vnet'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'ApiManagement'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Private Endpoint
// // resource privateEndPoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
// //   name: 'PE'
// //   location:location
// //   properties:{
// //     subnet: {
// //       id: resourceId('Microsoft.Network/virtualNetworks/subnets',privateEndpointSubnetName,apimCSVNetName)
// //     }
// //     privateLinkServiceConnections: [
// //       {
// //         name: privateLinkName
// //         properties: {
// //           privateLinkServiceId: functionId
// //           groupIds: [
// //             'AzureFunc'
// //           ]
// //         }
// //       }
// //     ]
// //   }
// // }

// Public IP 
resource pip 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Mind the PIP for bastion being Standard SKU, Static IP
resource pipBastion 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIPAddressNameBastion
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }  
}

resource bastion 'Microsoft.Network/bastionHosts@2020-07-01' = {
  name: bastionName
  location: location 
  tags:  {
    Owner: owner
  }
  properties: {
    ipConfigurations: [
      {
        name: bastionIPConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipBastion.id             
          }
          subnet: {
            id: '${vnetApimCs.id}/subnets/${bastionSubnetName}' 
          }
        }
      }
    ]
  }
} 



// Output section
output apimCSVNetName string = apimCSVNetName
output apimCSVNetId string = vnetApimCs.id

output bastionSubnetName string = bastionSubnetName  
output devOpsSubnetName string = devOpsSubnetName  
output jumpBoxSubnetName string = jumpBoxSubnetName  
output appGatewaySubnetName string = appGatewaySubnetName  
output privateEndpointSubnetName string = privateEndpointSubnetName  
output backEndSubnetName string = backEndSubnetName  
output apimSubnetName string = apimSubnetName

output bastionSubnetid string = '${vnetApimCs.id}/subnets/${bastionSubnetName}'  
output CICDAgentSubnetId string = '${vnetApimCs.id}/subnets/${devOpsSubnetName}'  
output jumpBoxSubnetid string = '${vnetApimCs.id}/subnets/${jumpBoxSubnetName}'  
output appGatewaySubnetid string = '${vnetApimCs.id}/subnets/${appGatewaySubnetName}'  
output privateEndpointSubnetid string = '${vnetApimCs.id}/subnets/${privateEndpointSubnetName}'  
output backEndSubnetid string = '${vnetApimCs.id}/subnets/${backEndSubnetName}'  
output apimSubnetid string = '${vnetApimCs.id}/subnets/${apimSubnetName}'  

output publicIp string = pip.id

