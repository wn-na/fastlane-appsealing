require 'fastlane'

module AppSealing
  def initialize(lane)
     @lane = lane
  end

  def self.absolute_path(path)
    return File.join(File.expand_path('../../', __FILE__ ), path)
  end
  
  def self.get_build_path()
    apk_path = @lane.lane_context[Fastlane::Actions::SharedValues::GRADLE_APK_OUTPUT_PATH].to_s
    aab_path =  @lane.lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH].to_s
    if apk_path.length > 0
      return apk_path
    elsif aab_path.length > 0
      return aab_path
    else
      throw Exception.new "fail to get android build path"
    end
  end

  # Verification
  # Run below command to verify installed AppSealing CLI tool, for that, ‘jar verified’ message will be displayed.
  def self.verifyAppsealingCli(path)
    puts "Check verify installed AppSealing CLI tool"

    cmd = "jarsigner -verify -verbose -certs #{path} | grep 'jar verified'" 

    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)

    stdout.each_line { |line| }
    stdin.close
    stdout.close
    stderr.close

    exitstatus = wait_thr.value.exitstatus
    puts ">> result: #{exitstatus == 0 ? "verified": "not verified"}"

    return exitstatus == 0
  end

  def self.getBoolean(key, value)
    if value == nil
      return nil
    end
    if value == true or value == false
      return value == true ? "yes" : "no"
    end
    throw Exception.new "#{key} option is invalid, please select true or false"
  end

  def self.getStringinOption(key, value, options)
    if value == nil
      return nil
    end
    for option in options
      if option == value
        return value
      end
    end

    throw Exception.new "#{key} option is invalid, please select one of the options below #{options}"
  end

  def self.getListinOption(key, value, options)
    if value == nil
      return nil
    end

    if value.kind_of?(Array)
      if value.empty?
        return nil
      elsif value.all? { |e| options.include?(e) }
        return "\"#{value.join(",")}\""
      end
    end
    throw Exception.new "#{key} option is invalid, please select the option you want as an array #{options}"
  end

  def self.createConfig(param)
    config = {}
    config[:config] = param[:config_path]
    config[:url] = param[:url] 
    config[:authkey] = param[:authkey]
    config[:srcapk] = param[:srcapk] ? param[:srcapk] : get_build_path()
    config[:sealedapk] = param[:sealedapk] ? param[:sealedapk] : './appsealing.apk'
    config[:service_version] = param[:service_version]

    # Deploy mode [ release | test ]
    config[:deploymode] = getStringinOption(
      "deploymode",
      param[:deploymode],
      ["release", "test"]
    )
    # App_type { GAME | NON_GAME }
    config[:app_type] = getStringinOption(
      "app_type",
      param[:app_type],
      ["GAME", "NON_GAME"]
    ) 

    # Dex Encryption option { no | yes }
    config[:dex_encrypt] = getBoolean("dex_encrypt", param[:dex_encrypt])

    # Select partial Dex Encryption option { no | yes }(default: no)
    config[:select_dex_encrypt] = getBoolean("select_dex_encrypt", param[:select_dex_encrypt])

    # Allow or block emulator and root device option { emulator, rooting }
    config[:block_environment] = getListinOption("block_environment", param[:block_environment], ["emulator", "rooting"])

    # List specific emulators which you want to allow when you already blocking emulator with 'block_environment' option { BlueStacks, Nox, LDPlayer, ...}
    config[:allow_emulator] = getListinOption("allow_emulator", param[:allow_emulator], ["BlueStacks", "Nox", "LDPlayer"])

    # Allow apps to run in environments with external tools installed option { macro, sniff }
    config[:allow_external_tool] = getListinOption("allow_external_tool", param[:allow_external_tool], ["macro", "sniff"])
  
    # Option to allow app to run in "work profile" environment { yes | no } (default: yes)
    config[:block_work_profile] = getBoolean("block_work_profile", param[:block_work_profile])

    # List specific work profile tools which you want to allow when you already blocking work profile environment. { Samsung SecureFolder }
    config[:allow_work_profiles] = getListinOption("allow_work_profiles", param[:allow_work_profiles], ["Samsung SecureFolder"])

    # Allow or block app to run at Developer Option enabled devices {yes | no} (default: no)
    config[:block_developer_options] = getBoolean("block_developer_options", param[:block_developer_options])

    # Option to allow app to run in keylogger installed environment { no | yes } (default: no (allow launch))
    config[:block_keylogger] = getBoolean("block_keylogger", param[:block_keylogger])

    # Option to prevent screen hijacking from screen mirroring or capture { yes | no } ( default : no (allow))
    config[:block_screen_capture] = getBoolean("block_screen_capture", param[:block_screen_capture])

    # Allow or block app to run in USB debugging enabled devices { yes | no } (default: yes)
    config[:block_usb_debugging] = getBoolean("block_usb_debugging", param[:block_usb_debugging])

    # AppSealing Service type { NATIVE_AOS | HYBRID_AOS }( default: NATIVE_AOS )
    config[:service_type] = getStringinOption(
      "service_type",
      param[:service_type],
      ["NATIVE_AOS", "HYBRID_AOS"]
    )
   
    # App's framework in HYBRID_AOS case { REACT_NATIVE | IONIC | CORDOVA } 
    config[:framework] = getStringinOption(
      "framework", 
      param[:framework], 
      ["REACT_NATIVE", "IONIC", "CORDOVA"]
    )

    # Option to collect Wi-Fi security protocol information { collect | disable } ( default : disable )
    config[:wifi_security_protocol] = getStringinOption(
      "wifi_security_protocol", 
      param[:wifi_security_protocol], 
      ["collect", "disable"]
    )

    # Option to prevent screen overlay windows from other app such as  macro or memory attack app { yes | no } ( default : no (allow))
    config[:hide_overlay_windows] = getBoolean("hide_overlay_windows", param[:hide_overlay_windows])

    # Use QUERY_ALL_PACKAGES permission { yes | no }(default : no)
    config[:use_query_all_packages] = getBoolean("use_query_all_packages", param[:use_query_all_packages])
    # App Signing Option for sealed app {none | appsealing_key | registered_key } (default : none)
    # none : AppSealing has been applied, but it has not been signed. In order to install it on the device or
    #          distribute it to the store, developer must sign it with a signing key.
    # appsealing_key : AppSealing is applied and signed with the debug key. The signed app can be installed on the device
    #		  		   and tested during development (evaluation) stage, but in order to distribute it to the store, 
    #		  		   developer must use the signed app with the distribution key. (For AAB package, this option applies
    #				   as 'none' value and the app is unsigned.)
    # registered_key : AppSealing is applied and signed with a pre-registered key. To use this option, developer must
    #				   pre-register the key to be used for app-signing in the AppSealing Developer Console (ADC).
    #				   Developers can download signed app that with distribution signing key. ('upload-key' if 'Google 
    #				   Play Signing is applied.)      
    config[:app_signing] = getStringinOption(
      "app_signing", 
      param[:app_signing], 
      ["none", "appsealing_key", "registered_key"]
    )
    return config
  end

  def self.build(param)
    @lane = param[:fastlane]
    if @lane == nil 
      puts "Make sure passed the fastlane value correctly"
      return -1
    end
    appsealing_jar_path = absolute_path(param[:cli_jar_path] ? param[:cli_jar_path] : "sealing.jar")
    # Check Appsealing jar verify
    raise Exception.new "** fail to verfiy appsealing cli tool" unless verifyAppsealingCli(appsealing_jar_path) 

    config = createConfig(param[:config])
    
    command = "java -jar #{appsealing_jar_path}"
    config.each do |k, v|
      if v != nil
        command = command << " -#{k} #{v}"
      end
    end 

    print "cmd: ", command, "\n"

    stdin, stdout, stderr, wait_thr = Open3.popen3(command)
    stdout.each_line { |line| 
      print "[#{Time.now.strftime("%T")}]: ▸ ", line
    }
    stdin.close
    stdout.close
    stderr.close

    exitstatus = wait_thr.value.exitstatus

    raise Exception.new "** fail to run appsealing (errorcode :#{exitstatus})" unless exitstatus == 0

    FileUtils.cp android_build_output, appsealing_output
  end
end
