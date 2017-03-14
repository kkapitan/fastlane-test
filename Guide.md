# Continuous Delivery with Fastlane

## Fastlane?

Fastlane is a set of command line tools created by Felix Krause and managed by Google as a part of Fabric mobile platform. It was initially designed to automate a tedious work that is codesigning and releasing iOS applications, but in the process it evolved into utility belt capable of dealing with work developers face on a daily basis, such as:

* Uploading the app along with the screenshots and metadata to AppStore/Google Play
* Taking screenshots for every device and localization supported
* Generating and renewing push notification profiles
* Creating and maintaining iOS code signing certificates
* Uploading the app to TestFlight and managing testers
* Uploading the app to any 3rd party service like HockeyApp or Fabric's Beta
* Building and codesigning the application
* Performing Unit and UI tests and generating reports based on the results
* Preparing custom page for tester to sign up for TestFlight build
* Synchronizing certificates and provisioning profiles for the team
* ... pretty much anything you can imagine due to its high extensibility

With little-to-no setup all of the above can be done for you.

## Instalation

First you need to ensure you have latest Xcode command line tools installed:

`xcode-select --install`

#### Homebrew

You can install fastlane via Homebrew:

`brew cask install fastlane`

#### Gem

Since fastlane is written in Ruby, you can also install it as a gem using:

`gem install fastlane`

*For more thorough guide on how to install or setup fastlane check [official guide](https://github.com/fastlane/fastlane#installation)*
#### Other



#### Bundler
