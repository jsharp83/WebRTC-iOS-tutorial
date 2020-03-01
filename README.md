# WebRTCIOSTutorial
This is a simple code for video call using WebRTC and iOS Swift.

## Motive

Nowaday, Video call is a very common feature in many app. So many people(including me) start to develop that feature with [WebRTC](https://webrtc.org/).

[This link](https://webrtc.github.io/webrtc-org/native-code/ios/) shows that how to use the WebRTC in iOS enviroment and
[this](https://webrtc.googlesource.com/src/+/refs/heads/master/examples/objc/AppRTCMobile/) is the official WebRTC iOS example. However it is based on Objective C and it covers too many feature so I think there is a learning curve when I first started.

Also there are some example app using swift but I needed to make the signal server and there is a limitation to check with other platforms app like Android and web. This app is follow the official WebRTC example, so you can test this app with different platform.

[This website](https://appr.tc/) is a WebRTC sample web. You can test the call with this app and web.

## Limitation
* I just use the Stun server for ice server in this example. So If you are on behide a NAT, there may be a problem.

## Todo
* Exceptional case handling
* Disconnect issuce check

### ETC
Additionally I developed the recording and image filter feature in video call. but I don't know it is useful for others. If I receive the request, I will add that feature in this example.

Feel free to use and fell free to contribute using PR.
