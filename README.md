# PotaMaps for iOS

PotaMaps is a tool for Parks on the Air activators.

Current features include:
* Searchable database of parks
* Information about previous activations at a park
* Directions to a park
* Built-in interface to spot your activation

## Installation Instructions
1. Install [Xcode](https://developer.apple.com/xcode/download/)
1. Install [Cocoapods](https://guides.cocoapods.org/using/getting-started.html)
1. Clone this git repository
1. Run `pod install` in the project directory.
1. Open "PotaMaps.xcworkspace" in Xcode
1. Go to Xcode's Preferences > Accounts and add your Apple ID
1. In Xcode's sidebar select "PotaMaps" then select "PotaMaps" under "Targets".  Select "General" at the top of the screen.  Change the Bundle Identifier (e.g. montynet.org.PotaMaps) to something unique.  Select your Apple ID in Signing > Team.
1. Connect your device using USB and select it in Xcode's Product menu (top left of the window).
1. Press Cmd+R or Product > Run to install PotaMaps.
1. If you install using a free (non-developer) account, make sure to rebuild PotaMaps every seven days, otherwise it will quit when your certificate expires.

## Contribution Guidelines
I am accepting pull requests to fix bugs or add/improve features.

For more info on POTA, check out https://parksontheair.com/