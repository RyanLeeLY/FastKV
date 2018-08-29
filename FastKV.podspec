#
# Be sure to run `pod lib lint FastKV.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FastKV'
  s.version          = '0.2.0'
  s.summary          = 'FastKV is a real-time and high-performance key-value components.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  FastKV is a real-time and high-performance key-value components based on mmap.
                       DESC

  s.homepage         = 'https://github.com/RyanLeeLY/FastKV'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yao.li' => 'liyaoxjtu2013@gmail.com' }
  s.source           = { :git => 'https://github.com/RyanLeeLY/FastKV.git', :tag => s.version.to_s }


  s.ios.deployment_target = '8.0'

  s.source_files = 'FastKV/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FastKV' => ['FastKV/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
