Pod::Spec.new do |s|
  s.name          = "IDMPhotoBrowser"
  s.summary       = "Photo Browser / Viewer inspired by Facebook's and Tweetbot's with ARC support, swipe-to-dismiss, image progress and more."
  s.version       = "1.3"
  s.homepage      = "https://github.com/ideaismobile/IDMPhotoBrowser"
  s.license       = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author        = { "Appkraft" => "all@appkraft.net" }
  s.source        = { :git => "https://github.com/ideaismobile/IDMPhotoBrowser.git", :tag => "1.3" }
  s.platform      = :ios, '7.0'
  s.source_files  = 'Classes/*.{h,m}'
  s.resources     = 'Classes/IDMPhotoBrowser.bundle'
  s.framework     = 'MessageUI', 'QuartzCore', 'SystemConfiguration', 'MobileCoreServices', 'Security'
  s.requires_arc  = true
  s.dependency      'AFNetworking', '~> 1.3.3'
  s.dependency      'DACircularProgress', '~> 2.1.0'
  s.dependency      'SVProgressHUD', '~> 0.9'
end