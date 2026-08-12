#
# Be sure to run `pod lib lint FlagShip.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = "FlagShip"
  s.version          = "4.0.3"
  s.summary          = "Flagship SDK"
  s.description      = <<-DESC
The FlagShip SDK is an iOS framework whose goal is to help you run Flagship campaigns on your native app.
                       DESC

  s.homepage         = "https://app.flagship.io/login"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'FlagShip' => 'adel@abtasty.com' }
  s.source           = { :git => 'https://github.com/flagship-io/flagship-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target  = "11.0"
  s.tvos.deployment_target = "11.0"
  s.osx.deployment_target = "10.13"
  s.swift_version = "5.0"
  s.default_subspec = "Core"

  # ABTasty-only (default). Does not link Wingify-FME.
  s.subspec "Core" do |core|
    core.source_files = "FlagShip/Source/**/*.swift"
    core.exclude_files = "FlagShip/Source/WingifyBridge/**/*"
  end

  # Dual-engine add-on. Use with Core: `pod 'FlagShip/Wingify'`.
  s.subspec "Wingify" do |wingify|
    wingify.dependency "FlagShip/Core"
    wingify.dependency "Wingify-FME", "~> 1.55"
    wingify.source_files = "FlagShip/Source/WingifyBridge/**/*.swift"
  end
end
