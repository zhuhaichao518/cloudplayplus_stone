#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gamepads_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gamepads_ios'
  s.version          = '0.1.1'
  s.summary          = 'iOS implementation of gamepads.'
  s.description      = <<-DESC
iOS implementation of gamepads, a Flutter plugin to handle gamepad input across multiple platforms.
                       DESC
  s.homepage         = 'https://flame-engine.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luan' => 'luan@blue-fire.xyz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
