#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cbl_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cbl_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Binaries required to use cbl in Flutter apps on iOS and macOS.'
  s.homepage         = 'https://github.com/cofu-app/cbl-dart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Gabriel Terwesten' => 'gabriel@terwesten.net' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency         'FlutterMacOS'
  s.platform         = :osx, '10.13'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version       = '5.0'

  s.prepare_command = <<-EOF
    ../tool/create_xcframeworks_links.sh
    ../tool/install_binaries.sh apple
  EOF

  s.vendored_frameworks = "Xcframeworks/CouchbaseLiteDart.xcframework", "Xcframeworks/CouchbaseLite.xcframework"
end
