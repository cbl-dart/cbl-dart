require 'open3'

# Globally activate the cbl_flutter package so we can use the `cbl_flutter_install` command.
stdout, stderr, status = Open3.capture3("dart pub global activate cbl_flutter ^3.2.0-dev.1")

unless status.success?
  puts "Failed to activate cbl_flutter:\n#{stdout}\n#{stderr}"
  exit(1)
end

# Install libraries if they have not been installed yet.
Dir.chdir("#{Dir.pwd}/..") do
  `cbl_flutter_install macOS`
end

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
  s.vendored_frameworks = 'Frameworks/*'
  s.dependency 'FlutterMacOS'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version       = '5.0'
end
