#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'file_share_intent'
  s.version          = '2.0.3'
  s.summary          = 'A flutter plugin that enables flutter apps to receive sharing photos from other apps.'
  s.description      = <<-DESC
A flutter plugin that enables flutter apps to receive sharing photos from other apps.
                       DESC
  s.homepage         = 'https://waltertay.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Walter' => 'walter@bookslice.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '12.0'
  s.frameworks = 'MobileCoreServices'
end

