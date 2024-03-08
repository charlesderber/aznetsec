targetScope = 'subscription'

param location string = 'norwayeast'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'demo-network'
  location: location
  tags: {
    owner: 'Charles Derber'
  }
}
