Pod::Spec.new do |s|
  s.name             = 'AlamofireObjC'
  s.version          = '5.12.2'
  s.summary          = 'An Objective-C bridge over Alamofire 5 — use Alamofire from pure ObjC.'

  s.description      = <<-DESC
    AlamofireObjC exposes 100% of Alamofire's user-facing feature set to Objective-C through
    a clean @objc API. It ships two layers: a chainable Alamofire-style core (AFOSession /
    AFORequest) and an AFNetworking-compatible facade (AFOHTTPSessionManager) for near
    drop-in migration off the deprecated AFNetworking. Includes NSOperation upload/download
    wrappers with userInfo passthrough, NSProgress and cancellation.
  DESC

  s.homepage         = 'https://github.com/RussianRoulette84/AlamofireObjC'
  s.license          = { :type => 'Unlicense', :file => 'LICENSE' }
  s.author           = 'Yaro'
  s.source           = { :git => 'https://github.com/RussianRoulette84/AlamofireObjC.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.swift_versions        = ['5.10']

  s.source_files = 'Sources/AlamofireObjC/**/*.swift'
  s.module_name  = 'AlamofireObjC'
  s.requires_arc = true

  # Alamofire stopped publishing to CocoaPods at 5.9.1 (5.10+ are SPM/GitHub only), so
  # CocoaPods installs the newest it can — our code is compatible with 5.9+. SPM/Carthage
  # pull the real 5.12 from GitHub.
  s.dependency 'Alamofire', '~> 5.9'

  # Objective-C consumability proof — pure .m test target that must compile against the
  # generated framework header. Run with `pod lib lint` / the generated Xcode test scheme.
  s.test_spec 'ObjCSurface' do |test|
    test.source_files = 'Tests/ObjCSurface/**/*.m'
    test.requires_app_host = false
  end

  # NOTE: This is a Swift pod consumed from Objective-C. Consumers MUST use `use_frameworks!`
  # in their Podfile so the generated AlamofireObjC-Swift.h header is produced inside the
  # framework. Static linkage works via `use_frameworks! :linkage => :static`.
end
