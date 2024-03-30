param location string = resourceGroup().location
param name string

@secure()
@description('Sets the Game Server Login Token for the server')
param gslt string

@secure()
@description('Sets the Steam Web API Key for the server required to download workshop mods')
param steamWebApiKey string

