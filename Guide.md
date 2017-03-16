# Continuous Delivery with Fastlane

## Table of contents

  * [Fastlane?](#fastlane)
  * [Installation](#installation)
      * [Homebrew](#homebrew)
      * [Gem](#gem)
      * [Bundler](#bundler)
      * [Other](#other)
  * [How to use](#how-to-use)
      * [Basics](#basics)
      * [Command line](#command-line)
      * [Fastfile](#fastfile)
      * [Environment variables](#environment-variables)
  * [Chosen tools](#chosen-tools)
      * [Pilot](#pilot)
      * [Boarding](#boarding)
      * [Cert](#cert)
      * [Match](#match)
      * [Snapshot](#snapshot)
  * [Advanced usage](#advanced-usage)
      * [Useful callbacks](#useful-callbacks)
      * [Lane context](#lane-context)
      * [Custom actions](#custom-actions)
      * [Ensuring security](#ensuring-security)
      * [Integration with Bitrise](#integration-with-bitrise)
      * [Known limitations](#known-limitations)
        * [Cert](#cert-1)
        * [Match](#match-1)
        * [Snapshot](#snapshot-1) 
        * [Gym](#gym)
  * [Examples](#examples)
  * [Troubleshooting](#troubleshooting)

## Fastlane?

Fastlane is an open source set of command line tools created by Felix Krause and managed by Google as a part of the Fabric mobile platform. It was initially designed to automate a tedious work that is code signing and releasing iOS applications, but in the process it evolved into utility belt, capable of dealing with work developers face on a daily basis, such as:

* Uploading the app along with the screenshots and metadata to AppStore/Google Play.
* Taking screenshots for every device and localization supported.
* Generating and renewing push notification profiles.
* Creating and maintaining iOS code signing certificates.
* Uploading the app to TestFlight and managing testers.
* Uploading the app to any 3rd party service like HockeyApp or Fabric's Beta.
* Building and code signing the application.
* Performing Unit or UI tests and generating reports based on the results.
* Preparing custom page for testers to sign up for TestFlight build.
* Synchronizing certificates and provisioning profiles across the team.
* ... pretty much anything you can imagine due to its high extensibility.

With little-to-no setup all of the above can be done for you.

## Installation

First you need to ensure you have latest Xcode command line tools installed:

```sh
xcode-select --install
```

#### Homebrew

You can install fastlane via Homebrew:

```sh
brew cask install fastlane
```
#### Gem

Since fastlane is written in Ruby, you can also install it as a gem using:

```sh
gem install fastlane
```
#### Bundler

The most recommended way of installing fastlane is to leverage the power of bundler. Bundler is a tool that ensures all your ruby dependencies are installed and executed in an isolated environment, independent from the machine it's being run on. It gives you the flexibility to bootstrap your project on any machine in no time, especially convenient if you're using any CI build system like `travis`.

To install bundler run:

```sh
gem install bundler
```

Then in your project directory create file named `Gemfile` with following contents:

```ruby
source 'https://rubygems.org'
gem 'fastlane'
```

And then run:
```sh
bundle install
```

**From now on each call to fastlane must be prefixed by `bundle exec`**

*Visit [the official site of a project](https://bundler.io) to check how to constraint your dependencies on a given version and more.*

#### Other
*For more thorough guide on how to install or setup fastlane check [the official guide](https://github.com/fastlane/fastlane#installation)*

## How to use

*From now on we assume that you've installed fastlane via bundler.*

#### Basics

Fastlane consists of independent actions, each responsible for performing specific task. The most popular ones are:

* `scan` - performs UI/Unit tests for your application
* `cert` - provides you with signing certificates suitable for your build
* `sigh` - provides you with provisioning files suitable for your build
* `gym` - builds and codesigns your app
* `pilot` - submits your app to TestFlight

To list all available actions use:

```sh
bundle exec fastlane actions
```

To check the description or parameters of a given action run:

```sh
bundle exec fastlane action [action_name]
```

For additional information you can also try:
```sh
bundle exec fastlane help
```

#### Command line

Since fastlane is a command line tool you can easily run any command via shell (e.g. bash). For example this

```sh
bundle exec fastlane scan
```

will start a process responsible for performing the tests. It will automatically figure out necessary data like your `.xcodeproj` or `.xcworkspace` file, or ask you to resolve any ambiguity faced on its way, e.g which scheme should be used for building the application or what are the devices to run the tests on.

Of course the execution is stopped until you answer, which proves to be a problem when working with batched environments like CI systems, where you are not able to interact with the process directly. That's why you can also specify additional parameters to resolve ambiguity at launch:

```sh
bundle exec fastlane scan --scheme "Production" --device "iPhone6"
```

#### Fastfile

However the real power of fastlane comes into play when using `Fastfile`. `Fastfile` is a ruby file with special structure where you can define `lanes` composed of
fastlane actions in order you'd like them to be executed. Of course since it's a ruby file you can pretty much use any ruby code here, but most of the time the tools provided by fastlane are sufficient. `Lanes` can also be nested inside `platforms` to give them more usage context. Here is the sample `Fastfile`:

```ruby
platform :ios do
  desc "Runs all the tests"
  lane :test do
    scan(scheme: "Production", devices: ["iPhone 6"])
  end
end
```

Here we define platform called `ios` which by its name will consist of lanes specific to iOS system. Inside this platform, we specify lane `test` that simply run `scan` with some arguments. The `desc` keyword here is used to provide additional description for our lane. It's a good practice to provide one.

You can now run this lane using:

```sh
bundle exec fastlane ios test
```

or in general:

```sh
bundle exec fastlane [platform_name] [lane_name]
```

For now it looks like we have exchanged one line shell command for six lines of ruby code, but let's look at another example:

```ruby
platform :ios do
  desc "Release to TestFlight"
  lane :release_testflight do
    increment_build_number

    import_certificate(
      keychain_name: "login.keychain"
      keychain_password: "Passw0rd!",
      certificate_path: "./artifacts/cert",
      certificate_password: "Passw0rd!",
    )

    # download provisioning profiles
    sigh

    # build
    gym

    # upload to TestFlight
    pilot
  end
end
```

In the above we define a lane that:
* increments number of the build
* imports certificate to keychain to be used later
* resolves and downloads any provisioning profiles needed
* builds the app and code signs it (using provisioning profiles and certificate supplied in previous steps)
* uploads the app to TestFlight

This sequence of steps encapsulated by the lane defines a clear and meaningful flow that can now be performed as a single command.

**You have probably noticed that here we specify such sensitive data like keychain/certificate password directly in the `Fastfile`. This is a real security issue that we will deal with in a moment.**

Imagine that in addition to releasing your build via TestFlight, you also need to upload it to some 3rd party service like HockeyApp. If you are using git for version control it may happen that each commit or merge to the master branch triggers the build for HockeyApp, but TestFlight release occurs only when pushing proper tag. Thus we should handle it by defining separate lanes. However if you think about it, both cases have a lot in common - the process of building the app remains unchanged, the only change comes in its destination.

To avoid breaching the DRY principle we can extract the steps responsible for building the app to a new private lane:

```ruby
desc "Build the application"
private_lane :build do |options|
  increment_build_number

  import_certificate(
    keychain_name: "login.keychain"
    keychain_password: "Passw0rd!",
    certificate_path: "./artifacts/cert",
    certificate_password: "Passw0rd!",
  )

  # download provisioning profiles
  sigh

  # build
  gym
end
```

And then we can reuse it when defining proper lanes:

```ruby
desc "Upload to hockey"
lane :release_hockey do
  # build the app
  build

  # upload to HockeyApp
  hockey
end

desc "Upload to TestFlight"
lane :release_testflight do
  # build the app
  build

  # upload to TestFlight
  pilot
end
```

Notice that in line `private_lane :build do |options|` we defined additional `options` variable. It is a dictionary
(or hash if you are familiar with ruby) you can use to supply your lane with own parameters. In our case we can specify whether the build should be considered as ad-hoc by `build({adhoc: true})` and then handle this case in implementation of our lane.

#### Environment variables

There is more! Each parameter of an action is backed up by an environment variable. You can check available parameters along with equivalent environment variables using:

```sh
bundle exec fastlane action [action_name]
```

Using environment variables we can extract all parameters from the Fastfile into another file. This can be useful if you intend to use fastlane as a part of your CI process. The number of necessary arguments in this case can be a little overwhelming and specifying them all via Fastfile would only make our flow less readable.

There are two types of environment variables depending on their scope. The first ones are variables operating on a global level, that means their scope includes each defined lane. These are stored in `.env` or `.env.default` files in the same directory as your `Fastfile`. We can rewrite one of the previous examples using environment variables. This lane:

```ruby
platform :ios do
  desc "Runs all the tests"
  lane :test do
    scan(scheme: "Production", devices: ["iPhone 6"])
  end
end
```

will end up being:

```ruby
platform :ios do
  desc "Runs all the tests"
  lane :test do
    scan
  end
end
```
with `.env` file like:

```ruby
SCAN_SCHEME="Production"
SCAN_DEVICES="iPhone 6"
```

There are also lane-scoped environment variables. As in their name - these variables are valid only for the lane they are being scoped to. It's worth noting that lane-scoped variables will overwrite the global-scoped ones. This can be useful when handling different app environments like staging or production. Imagine that in the previous example we want to perform tests for staging scheme as well e.g. before submitting the build to HockeyApp. We can reuse the same lane defined above but provide it with different `SCAN_SCHEME`. In order to do that let's create another file called `.env.staging`:

```ruby
SCAN_SCHEME="Staging"
```

Now we need to specify which environment variables to load for our lane:

```sh
bundle exec fastlane ios test --env staging
```

In general:

```sh
--env [environment_name]
```

will read environment variables stored in `.env.[environment_name]`.

The `SCAN_SCHEME` will be now changed to `Staging` and the `SCAN_DEVICES` should still be `iPhone 6` since we didn't overwrite this variable in `.env.staging` file.

The most common pattern is to store any app environment specific values as lane-scoped environment variables, while those shared by all configurations via `.env` or `.env.default`.

To access the contents of environment variable explicitly you can use `ENV["name_of_the_variable"]` inside `Fastfile`. It's a common case if you are using custom variables.

```ruby
platform :ios do
  desc "Runs all the tests"
  lane :test do
    scan(scheme: ENV["CUSTOM_VARIABLE_SPECIFYING_SCHEME"])
  end
end
```

## Chosen tools

### Pilot
<p align=center>
<em>For more detailed info visit official pilot page <a href="https://github.com/fastlane/fastlane/tree/master/pilot">here</a></em>
</p>

The purpose of pilot is to upload your build to TestFlight while also managing the associated testers.

If you want to upload your build just execute:

```sh
bundle exec fastlane pilot upload
```

It will then ask you about your credentials for your iTunes Connect account alongside the id of an app you want to upload. By default it assumes that the signed `.ipa` file is present in the current directory. You can also specify all necessary parameters either via shell or by defining environment variables as described [here](#how-to-use).

You can add or remove testers one by one:

```sh
fastlane pilot add [email]
fastlane pilot remove [email]
```

Or import/export all of them from/to the `.csv` file:

```sh
fastlane pilot import -c [path_to_csv]
fastlane pilot export -c [path_to_write_file]
```

With following format:

```csv
[name],[surname],[email]
```

### Boarding
<p align=center>
<em>For more detailed info visit official boarding page <a href="https://github.com/fastlane/boarding">here</a></em>
</p>

Boarding is a tool used to setup custom page for your TestFlight testers to sign up. It gives the possibility to add testers in a reactive-like manner - instead of specifying emails by yourself, you can share the page with your testers, allowing them to signup on their own.

To setup this page you need to have an account on `Heroku`. Then the only thing to do is to fill the data [here](https://www.heroku.com/deploy?template=https://github.com/fastlane/boarding).

Boarding will automatically figure out the rest and create a page. It is also possible to use your own template which requires forking the boarding github repository. The files:

* `invite_controller.rb`
* `invite/index.html.erb`

are the entry point for you to modify.

The nice addition here is a possibility to track the visitors via Google Analytics out of the box.

### Cert
<p align=center>
<em>For more detailed info visit official boarding page <a href="https://github.com/fastlane/fastlane/tree/master/cert">here</a></em>
</p>
What it is?

Cert is a tool for downloading existing or create a new signing certifacte and working with locally installed for different enviroments.

It is working great with an another `Fastlane` tool `sigh`.

The most easiest way of using `cert` is to create lane with it.

```ruby
  desc "Download signing certyficate"
  lane :cert_test do |options|
    cert
  end
```

And call

``sh
bundle exec fastlane ios cert_test
``

But in that case, `cert` will ask about your Apple ID, password and throw an outputted files into the project's folder. We can fix asking about ID and tell where an output files should be located by passing an argument to `cert`.

```ruby
  desc "Download signing certyficate"
  lane :cert_test do |options|
    cert (
      username: "my@apple.id"
      output_path: "./fastlane/cert",
    )
  end
```

But what about password? It can be stored in .env var `FASTLANE_PASSWORD` what is more `username` and `output_path` can be and should be stored in .env file.

To read more about `.env` files read [environment variables](#environment-variables)

Let say we have a `.env.staging` file

```
CERT_USERNAME="blazej@wdowikowski.pl"
CERT_DEVELOPMENT=true
CERT_OUTPUT_PATH="./fastlane/cert"
FASTLANE_PASSWORD = "<PASSWORD>"
```

```ruby
  desc "Download signing certyficate"
  lane :cert_test do |options|
    cert
  end
```

And finally call

``sh
bundle exec fastlane ios cert_test --env staging
``

### Match

What it is? Why it could be use instead of cert&sign
how you use it?

### Snapshot

What it is?
how you use it?

## Advanced usage

### Useful callbacks

A bunch of useful callbacks:
```ruby
# invoked at the start of execution
before_all do |lane, options|
  ...
end

# invoked at the start of execution of a lane
before_each do |lane, options|
  ...
end

# invoked at the end of successful execution
after_all do |lane, options|
  ...
end

# invoked at the end of successful execution of a lane
after_each do |lane, options|
  ...
end

# invoked if an error is thrown
error do |lane, exception, options|
  ...
end
```

You can use them to clean build artifacts or to send notification that a given build resulted with success/error - for example via slack.

### Lane context

At this point maybe you are wondering - how does it actually work? Especially how does each action interacts with another? We've mentioned in one of the examples that `sigh` is responsible for downloading provisioning profiles, but how does it pass the gathered data to `gym` so it can then code sign the app properly? There is no explicit communication between these two when you look at the lane implementation. The answer is... the lane context!

Lane context is a shared dictionary (or hash) used to store and manage the side effects of each action such as the data gathered in the process of execution. Accessing the lane context is possible via this syntax:

```ruby
Actions.lane_context[SharedValues::VALUE_NAME]
```

Since each step depends on the effects of the previous one, by modifying particular entries in the lane context you can act as a middle-man or omit some steps entirely, given that you will provide necessary values by yourself.

### Custom actions

As it was mentioned before, fastlane was designed to be a highly extensible tool. That's why it gives you the ability to create your own custom actions. However before you do that it is advised to check if any of the base actions will suffice for your particular use case. Fastlane has a huge open source community devoted to extend its capabilities as lots and lots of actions created by external developers are being merged into the default set. It is usually better to use some production ready and battle tested tool than making it from scratch.  

So you've done your research and still you are certain that a custom action is what to aim for. Start with:

`bundle exec fastlane new_action`

After entering your action's name fastlane will generate the template at `fastlane/actions/[action_name].rb` that you need to fill. Alongside the general implementation you'll have to provide it with thorough description of how to interact with your action and what are the effects of the execution.

You can use this action in the `Fastfile` just like any other by calling its name.

### Ensuring security

As we have mentioned before specifying the sensitive data directly in your `Fastfile` or as an entry in one of the files from `.env` family is a serious security breach.

If you intend to use fastlane on your local machine you may use tools like [`cocoapods-keys`](https://github.com/orta/cocoapods-keys) to store your keys securely using keychain. You can also use it as a part of your CI system, but then it searches for the keys in the environment variables you set as a part of the CI configuration.

Part of the process requires you to specify the certificate to sign your application with. If you use version control **DO NOT** include your certificate to the set of versioned files, especially if you use services like GitHub to store your repository, as this will expose your data to the public. For the CI purpose, to handle the issue of providing fastlane with the certificate you can use its own tool `match`.

However if you for some reason choose not to leverage `match` you'll need to find another way. You can use [Google Cloud Platform](https://cloud.google.com/) and the tool it's providing - `gsutil`. Using `gsutil` you can securely upload/download your data stored as a bucket in the cloud. In particular it may look like that:

* On your local machine:
  1. Prepare the folder with the certificate. You can also put there some additional files (e.g `.env.ci`) with some protected environment variables (like keychain password or name of the certificate).
  2. Upload it to the Google Cloud Platform using `gsutil`.
* As a part of CI configuration:
  1. Setup environment variables necessary to gain access to the uploaded bucket.
  2. Authorize and download the bucket via `gsutil`.
  3. Use `source` command to inject the environment variables specified in `.env.ci` file to current shell.

You can write your own fastlane action encapsulating this process for greater reusability among all of your projects.

### Integration with Bitrise

**TODO Write about how to integrate with bitrise**

### Known limitations

#### Cert
**TODO Write about issues with Cert**
Not founded yet.

#### Match
**TODO Write about issues with match**

#### Snapshot
**TODO Write about issues with snapshot**

#### Gym

Since Xcode 8 introduced new system of automatic signing it happens that sometimes this interferes with the work done by fastlane. That makes following error `Code signing is required for product type 'Application' in SDK 'iOS 10.x'` appear randomly while building the app via `gym`. To avoid this heisen-issue you may turn off the automatic signing in Xcode and specify the following in project's `.xcconfig` files related to the scheme you're building.

```ruby
PROVISIONING_PROFILE_SPECIFIER = <PROVISIONING_PROFILE_NAME>
DEVELOPMENT_TEAM = <TEAM_ID>
```

*Note that you need to specify the provisioning profile's name, not UUID*

The other solution is to use `match` as it handles this case for you.

## Examples

You can find a lot of examples [here](https://github.com/fastlane/examples). All of the fastlane setups there are already being used in production. If you are looking for a particular case there is a detailed description of each setup in `README.md`.

## Troubleshooting

Fastlane automates a lot - still this is just a tool to help you in a rather complicated process of managing/releasing your application. Due to that complexity it is common to encounter some obstacles on your way, especially if you are just starting your adventure with fastlane. The important part here is to know how to deal with them smoothly.

First of all ensure you understand what you are trying to achieve. If this is a release - check if you are familiar with the process of building and code signing your application. Fastlane can automate many things, but remember that you are the "brains" behind the process. In this case knowledge is crucial - if you catch yourself blindly updating `Fastfile` with more and more code, hoping it will eventually work, consider taking a break and think about the goal. How would you do it by hand? Does the `Fastfile` reflect your intention?

Fastlane is very well documented. Most of the variables and actions are backed by meaningful and clear description. However if you have any doubts or you're wondering if some kind of operation is supported or maybe you want to understand a little better how things work, a good place to start is the documentation [here](https://docs.fastlane.tools/). If you have some particular use case in mind you can also check the examples [here](https://github.com/fastlane/examples).

If any of fastlane actions throws an error the additional message is attached which sometimes can direct you right on the point. Alongside the error description fastlane usually provides you with links to GitHub issues which might address your problem. Take some time to get familiar with them. You can also search for issues on GitHub on your own. Fastlane has a great community willing to help and there is a high chance that the problem you are facing has already been solved in the past.

Imagine the following scenario - you've manage to setup your lanes correctly. You are now benefiting from automated delivery system for over a month, your boss is happy and your nerves are happy. You also saved a plenty of time for you and your team to focus on more exciting things! And one day... it crashes. And again. And again. You're retriggering the builds like crazy, but it gives you nothing.

Check if some part of the setup changed. Maybe your certificate or provisioning has expired. Maybe you've changed the version of Xcode - that was the case when upgrading to Xcode 8 and its system of automatic signing. There is also another possibility. Fastlane interacts with Apple Developer Portal which does not have any official API. This portal tends to change a lot and in rare cases it also requires the change in how fastlane handle things internally. It happened few times over past year, but the fastlane team reacts very quickly. Check some GitHub issues to ensure that other developers encounter the same problem and consider upgrading your fastlane version using:
```sh
bundle update fastlane
```

It may also happen that Apple Developer Portal is under maintenance - you can check it [here](https://developer.apple.com/system-status/) - in that case just wait for the restore and try then.

If and only if all of the above fails you can create an issue detailing your problem on [GitHub](https://github.com/fastlane/fastlane/issues). Fill the issue template and follow the checklist there. Remember to be polite and to use proper language - everybody prefers working in kind and healthy environment. This increases your chances to be noticed and provided with necessary help.
