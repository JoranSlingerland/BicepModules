//Paramaters
param location string
param imageGalleryName string
param tags object

//Deployment
resource imageGallery 'Microsoft.Compute/galleries@2019-03-01' = {
  name: imageGalleryName
  location: location
  tags: tags
  properties: {}
}
