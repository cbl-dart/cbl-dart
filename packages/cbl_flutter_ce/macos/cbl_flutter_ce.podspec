# Install libraries if they have not been installed yet.
`../tool/install_libraries.sh macos`

Pod::Spec.new do |s|
  s.name                = 'cbl_flutter_ce'
  s.version             = '0.0.1'
  s.summary             = 'Prebuilt Couchbase Lite libraries'
  s.description         = 'Prebuilt Couchbase Lite libraries'
  s.homepage            = 'https://github.com/cbl-dart/cbl-dart'
  s.license             = { :file => '../LICENSE' }
  s.author              = { 'Gabriel Terwesten' => 'gabriel@terwesten.com' }
  s.platform            = :osx, '10.14'
  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.vendored_libraries  = 'Libraries/*'
  s.dependency 'FlutterMacOS'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version       = '5.0'
end
