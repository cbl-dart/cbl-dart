# Install libraries if they have not been installed yet.
`../tool/install_libraries.sh ios`

Pod::Spec.new do |s|
  s.name                = 'cbl_flutter_ee'
  s.version             = '0.0.1'
  s.summary             = 'Prebuilt Couchbase Lite libraries'
  s.description         = 'Prebuilt Couchbase Lite libraries'
  s.homepage            = 'https://github.com/cbl-dart/cbl-dart'
  s.license             = { :file => '../LICENSE' }
  s.author              = { 'Gabriel Terwesten' => 'gabriel@terwesten.com' }
  s.platform            = :ios, '10.0'
  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/*'
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version       = '5.0'
end
