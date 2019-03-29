Pod::Spec.new do |s|
  s.name             = 'LiddleUI'
  s.version          = '0.1.0'
  s.license          =  { :type => 'SDK', :file => 'LICENSE'}
  s.homepage         = 'www.liddle.com'
  s.summary          = 'LiddleUI is a library of useful User Interface components for Liddle Soft'
  s.authors          = 'Peter Liddle'

 # s.source           = { :git => "https://github.com/ParsePlatform/ParseUI-iOS.git", :tag => s.version.to_s }
 s.source           = { :path => "/Users/peter/Development/iOS/LiddleUI"}


  s.platform              = :ios
  s.requires_arc          = true
  s.ios.deployment_target = '8.0'

  # s.prepare_command     = <<-CMD
  #                         ruby ParseUI/Scripts/convert_images.rb \
  #                              ParseUI/Resources/Images/ \
  #                              ParseUI/Generated/PFResources
  #                         CMD
  s.source_files        = "LiddleUI/**/*.swift"
  s.frameworks          = 'Foundation',
                          'UIKit'

  # s.dependency 'Bolts/Tasks', '~> 1.3'
  s.dependency 'Parse', '~> 1.12'
end