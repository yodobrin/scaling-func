@description('The location of the resource group and the location in which all resurces would be created')
param location string = resourceGroup().location
param serverName string = 'azsql${uniqueString(resourceGroup().id)}'

param sqlAdministratorLogin string
@secure()
param sqlAdministratorLoginPassword string



resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    version: '12.0'
  }
}

resource controlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: 'control'
  location: location
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  sku: {    
    family: 'string'
    name: 'Basic'
    tier: 'Basic'
  }
  parent: sqlServer
  properties: {
    autoPauseDelay: 1
    catalogCollation: 'DATABASE_DEFAULT'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    isLedgerOn: false
    licenseType: 'LicenseIncluded'
    zoneRedundant: false
  }
}



module azFunc 'azfunc.bicep' = {
  name: 'azFunc'
  params: {
    location: location
    sqlConnectionString: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlServer}::control;User Id=${sqlServer.properties.administratorLogin}@${sqlServer.properties.fullyQualifiedDomainName};Password=${sqlAdministratorLoginPassword};'    
  }
}
