require 'open3'

# Resolve absolute path to the Dart executable.
flutter_root = ENV['FLUTTER_ROOT']
if flutter_root.nil?
  puts "FLUTTER_ROOT environment variable not set."
  exit(1)
end

dart_executable = "#{flutter_root}/bin/cache/dart-sdk/bin/dart"

# Globally activate the cbl_flutter_install package so we can use the `cbl_flutter_install` command.
stdout, stderr, status = Open3.capture3("#{dart_executable} pub global activate cbl_flutter_install 0.1.0+1")

unless status.success?
  puts "Failed to activate cbl_flutter_install:\n#{stdout}\n#{stderr}"
  exit(1)
end

# Install libraries if they have not been installed yet.
Dir.chdir("#{Dir.pwd}/..") do
  `#{dart_executable} pub global run cbl_flutter_install iOS`
end

Pod::Spec.new do |s|
  s.name                = 'cbl_flutter_ce'
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
