# AddLive OS X SDK Tutorials

This repository contains several objectve-C project showcasing the basics
of the AddLive OS X SDK functionality.

For more details please refer to AddLive home page: http://www.addlive.com.

## Tutorial 1 - platform init

This tutorial covers platform initialization and calling service methods.

The sample application showcasing the functionality simply loads the SDK, calls 
the getVersion method and displays the version string in a label.

## Tutorial 2 - Devices handling

This tutorial covers devices handling, local preview control and rendering.

The sample application implemented, initializes the platform, sets up camera
devices, starts local video and renders it using ALVideoView components 
provided.

## Tutorial 3 - Rendering

The sample application provides a brief overview of how the AddLive platform
displays video feed. In the tutorial, there is a single renderer employed
and a widget allowing one to change the camera settings.

## Tutorial 4 - Basic connectivity

This example cover the core of the AddLive functionality - connectivity to the
media scope.

The example applicaiton provides a functionality of a one-to-one video
chat room.

## Tutorial 5 - Advanced devices handling

This tutorial covers more advanced handling of the media devices:

- getting the details about host CPU
- handling device list changed events
- rendering speech level
- testing the speakers

## Tutorial 6 - Advanced connectivity

This tutorial covers more advanced handling of the connectivity

- an ability to control which media are published
- handling of remote peer publish/unpublish events
- display of the connection type
- connection lost and reconnected handling
- an ability to specify custom scope

## License

All code examples provided within this repository are available under the
MIT-License. For more details, please refer to the LICENSE.md
