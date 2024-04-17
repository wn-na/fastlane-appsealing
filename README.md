## How to use

1. download `Appsealing.rb` in `fastlane` folder

2. modify `Fastfile`
   Example
```ruby
require './appsealing/Appsealing.rb'

...
  lane :appsealing do |options|
    AppSealing.build(
      fastlane: self,
      cli_jar_path: 'sealing.jar',
      config: {
        url: "https://api.appsealing.com/covault/gw",
        authkey: ENV["APP_SEALING_KEY"],
        service_type: "HYBRID_AOS",
        framework: "REACT_NATIVE",
        app_type: "NON_GAME",
        deploymode: "release",
        app_signing: "none",
        dex_encrypt: false,
        block_environment: ["emulator", "rooting"],
        allow_emulator: [],
        block_work_profile: true,
        allow_work_profiles: ["Samsung SecureFolder"],
        allow_external_tool: [],
        block_keylogger: true,
      }
    )
  end

```
