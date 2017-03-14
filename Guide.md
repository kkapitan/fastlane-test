# Continuous Delivery with Fastlane

## Fastlane?

Fastlane is an open source set of command line tools created by Felix Krause and managed by Google as a part of Fabric mobile platform. It was initially designed to automate a tedious work that is codesigning and releasing iOS applications, but in the process it evolved into utility belt capable of dealing with work developers face on a daily basis, such as:

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

#### Bundler

The most recommended way of installing fastlane is to leverage the power of bundler. Bundler is a tool that ensures all your ruby dependencies are installed and executed in an isolated environment independent from the machine it's being run on. It gives you the flexibility too bootstrap your project on any machine in no time, especially convenient if you're using any CI build system like `travis`.

To install bundler run:

`gem install bundler`

Then in your project directory create file named `Gemfile` with following contents:

```
source 'https://rubygems.org'
gem 'fastlane'
```

And then run:

`bundle install`

**From now on each call to fastlane must be prefixed by `bundle exec`**

*Visit [official site of a project](https://bundler.io) to check how to constraint your dependencies on a given version and more.*

#### Other
*For more thorough guide on how to install or setup fastlane check [official guide](https://github.com/fastlane/fastlane#installation)*

## How to use

*From now on we assume that you've installed fastlane via bundler.*

#### Basics

Fastlane consists of independent actions, each responsible for performing specific task. The most popular ones are:

* `scan` - performs UI/Unit tests for your application
* `sigh` - provides you with provisioning files suitable for your build
* `gym` - builds and codesigns your app
* `pilot` - submits your app to TestFlight

To list all available actions use:

`bundle exec fastlane actions`

To check the description or parameters of a given action run:

`bundle exec fastlane action [action_name]`

You can also try `bundle exec fastlane help` for additional information.

#### Command line

Since fastlane is a command line tool you can easily run any command via shell (e.g. bash). For example this

`bundle exec fastlane scan`

will start a process responsible for performing the tests. It will automatically figure out necessary data like your `.xcodeproj` or `.xcworkspace` file, or ask you to resolve any ambiguity faced on its way, e.g which scheme should be used for building the application or what are the devices to run the tests on.

Of course the execution is stopped until you answer, which proves to be a problem when working with batched environments like CI systems, where you are not able to interact with the process directly. That's why you can also specify additional parameters to resolve ambiguity at launch:

`bundle exec fastlane scan --scheme Production --device "iPhone6"`

#### Fastfile

However the real power of fastlane comes into play when using `Fastfile`. `Fastfile` is a ruby file with special structure where you can define `lanes` composed of
fastlane actions in order you'd like them to be executed. Of course since it's a ruby file you can pretty much use any ruby code here, but most of the time the tools provided by fastlane are sufficient. `Lanes` can also be nested inside `platforms` to give them more usage context. Here is the sample `Fastfile`:

```
platform :ios do
  desc "Runs all the tests"
  lane :test do
    scan(scheme: "Production", devices: ["iPhone 6"])
  end
end
```

Here we are defining platform called `ios` which by its name will consist of lanes specific to iOS system. Inside this platform, we specify lane `test` that simply run `scan` with some arguments. The `desc` keyword here is used to provide additional description for our lane. It's a good practice to provide one.

You can now run this lane using:

`bundle exec fastlane ios test`

or in general:

`bundle exec fastlane [platform_name] [lane_name]`


#### Environments



## Examples [WIP]

### Performing tests

### Uploading to HockeyApp

### Uploading to TestFlight
