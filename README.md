# SkipKeychain

This is a [Skip](https://skip.tools) Swift/Kotlin library project providing a simple unified API to secure key/value storage. It uses the Keychain on Darwin platforms and EncyptedSharedPreferences on Android.

## Usage

```swift
import SkipKeychain

let keychain = Keychain.shared

try keychain.set("value", forKey: "key")
assert(keychain.string(forKey: "key") == "value")

try keychain.removeValue(forKey: "key")
assert(keychain.string(forKey: "key") == nil)
```

## Backups

Google recommends excluding encrypted shared preference files from backups to prevent restoring an encrypted file whose encryption key is lost. Follow the instructions [here](https://developer.android.com/identity/data/autobackup#include-exclude-android-12) to create backup rules for your app. Your rules should contain the following to exclude the SkipKeychain shared preferences file:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <cloud-backup>
    <exclude domain="sharedpref" path="tools.skip.SkipKeychain.xml"/>
  </cloud-backup>
  <device-transfer>
    <exclude domain="sharedpref" path="tools.skip.SkipKeychain.xml"/>
  </device-transfer>
</data-extraction-rules>
```

## Building

This project is a Swift Package Manager module that uses the
[Skip](https://skip.tools) plugin to transpile Swift into Kotlin.

Building the module requires that Skip be installed using 
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.
This will also install the necessary build prerequisites:
Kotlin, Gradle, and the Android build tools.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.
