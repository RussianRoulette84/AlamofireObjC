![Version](https://img.shields.io/badge/Version-5.12.1-orange?style=for-the-badge)
![Swift](https://img.shields.io/badge/Swift-5.10-orange?style=for-the-badge&logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20·%20macOS%20·%20tvOS%20·%20watchOS-lightgrey?style=for-the-badge&logo=apple&logoColor=white)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-success?style=for-the-badge&logo=swift&logoColor=white)
![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-success?style=for-the-badge&logo=cocoapods&logoColor=white)
![License](https://img.shields.io/badge/License-Unlicense_(free_for_all)-9cf?style=for-the-badge)
[![Built on Alamofire](https://img.shields.io/badge/Built_on-Alamofire_5-E74C3C?style=for-the-badge)](https://github.com/Alamofire/Alamofire)

![Icon](icon.png)

# AlamofireObjC

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║   IF    you're the kind of guy who uses AFNetworking/Alamofire for decades       ║
║                                                                                  ║
║   AND   refuses to abandone Objective C in favor of the                          ║
║         "I can't make up my mind?(?)!" language, called Swift                    ║
║                                                                                  ║
║   THEN  this repoo is for you 😎                                                 ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

Alamofire is Swift-only and [AFNetworking is deprecated/archived](https://github.com/AFNetworking/AFNetworking) (since Jan 2023). `AlamofireObjC` bridges the gap: a clean `@objc` API exposing Alamofire's full feature set to Objective-C, plus an AFNetworking-style facade for near drop-in migration.

**Original library:** [Alamofire/Alamofire](https://github.com/Alamofire/Alamofire) (Swift). `AlamofireObjC` is an `@objc` bridge on top of it — it does not fork or vendor Alamofire, it depends on it.
**Versioning:** the major.minor mirrors the Alamofire it wraps; the last component is ours.
So `5.12.1`, `5.12.2`, … all track **Alamofire 5.12**, and when Alamofire ships 5.13 we move to
`5.13.1`. (Note: Alamofire only publishes to CocoaPods up to **5.9.1** — SPM/Carthage get the
real 5.12; CocoaPods installs 5.9.1, which our code is compatible with.)

**Warning**: Claude made it while I held it's hand

# Extra

- `NSOperation` async upload/download wrappers (serial queue + `userInfo` passthrough)
- AFNetworking-compatible `AFOHTTPSessionManager` facade

## Features Bridged

- Chainable request / response methods
- URL / JSON / plist parameter encoding
- Upload File / Data / Stream / MultipartFormData
- Download using request or resume data
- Authentication with `NSURLCredential`
- HTTP response validation
- TLS certificate and public-key pinning
- Progress closures & `NSProgress`
- cURL debug output
- WebSocket client (`AFOWebSocketTask`, on native `URLSessionWebSocketTask`)
- Exponential-backoff retry (`AFORetryPolicy`)

### Other Unmaintained Alamofire Obj C repos

Every existing attempt to use Alamofire from Objective-C is stale (newest is 2022, none are maintained bridges):

- [catalinaturlea/Alamofire](https://github.com/catalinaturlea/Alamofire) — Alamofire fork with an ObjC bridge from a 2015 Medium guide (Alamofire 3 era).
- [SilongLi/AFN-Alamofire-NetWorkingDemo](https://github.com/SilongLi/AFN-Alamofire-NetWorkingDemo) — demo wrapping AFNetworking (ObjC) and Alamofire (Swift) (2017).

That unfilled gap is exactly what this library exists to close.

## Requirements

| | |
|---|---|
| Platforms | iOS 16+ (macOS 13+, tvOS 16+, watchOS 9+ declared) |
| Xcode / Swift | Xcode 16+, Swift 5.10 |
| Dependency | [Alamofire](https://github.com/Alamofire/Alamofire) `~> 5.12` (pulled automatically) |

## Install

### CocoaPods
```ruby
use_frameworks!
pod 'AlamofireObjC', '~> 5.12'
```

> **⚠️ You must use `use_frameworks!`.** This is a Swift library consumed from Objective-C, so the bridge ships as a framework. In your `Podfile`, `use_frameworks!` (or `use_frameworks! :linkage => :static`) is required.

### Swift Package Manager
```
https://github.com/RussianRoulette84/AlamofireObjC.git  →  from: 5.12.1
```

### Carthage
```
github "RussianRoulette84/AlamofireObjC" ~> 5.12
```
`carthage build --use-xcframeworks`

## Import

```objc
@import AlamofireObjC;
// or
#import <AlamofireObjC/AlamofireObjC-Swift.h>
```

## Quick start — chainable core

```objc
AFOSession *session = AFOSession.shared;

[[[session request:@"https://api.example.com/users"
            method:AFOHTTPMethodGet
        parameters:nil
          encoding:AFOParameterEncodingURLDefault
           headers:@{@"X-Token": token}]
   validate]
   responseJSON:^(AFOResponse *response) {
       if (response.error) { NSLog(@"failed: %@", response.error); return; }
       NSDictionary *json = response.value;
       NSLog(@"users: %@", json);
   }];
```

## Multipart image upload

```objc
AFOMultipartFormData *form = [AFOMultipartFormData new];
[form appendData:imageData name:@"userfile" fileName:@"image.jpg" mimeType:@"image/jpeg"];

[[session uploadMultipart:form
                       to:uploadURL
                   method:AFOHTTPMethodPost
                  headers:@{@"X-Token": token}]
   uploadProgress:^(NSProgress *progress) { /* update UI */ }];
```

## Serial upload queue (NSOperation)

```objc
NSOperationQueue *queue = [NSOperationQueue new];
queue.maxConcurrentOperationCount = 1;        // serial

AFORequestOperation *op =
  [AFOUploadOperation multipartOperationWithSession:session
                                              form:form
                                         URLString:uploadURL
                                            method:AFOHTTPMethodPost
                                           headers:headers
                                          userInfo:@{@"pinID": pinID}    // echoed back
                                          progress:nil
                                           success:^(NSURLSessionTask *task, id obj, id userInfo) { /* ... */ }
                                           failure:^(NSURLSessionTask *task, NSError *err, id userInfo) { /* ... */ }];
[queue addOperation:op];
```

## AFNetworking-style facade

```objc
AFOHTTPSessionManager *manager = [AFOHTTPSessionManager managerWithBaseURL:[NSURL URLWithString:@"https://api.example.com"]];
manager.requestEncoding = AFOParameterEncodingJSON;
manager.removesKeysWithNullValues = YES;
manager.defaultHeaders = @{@"X-Token": token};

[manager get:@"/users" parameters:nil headers:nil progress:nil
     success:^(NSURLSessionTask *task, id responseObject) { /* ... */ }
     failure:^(NSURLSessionTask *task, NSError *error) { /* ... */ }];
```

## TLS pinning

```objc
AFOServerTrustPolicy *policy =
  [AFOServerTrustPolicy pinnedCertificates:@[derCertData] acceptSelfSigned:NO
                  performDefaultValidation:YES validateHost:YES];
AFOServerTrustManager *trust =
  [[AFOServerTrustManager alloc] initWithPolicies:@{@"api.example.com": policy}
                          allHostsMustBeEvaluated:NO];
AFOSession *session =
  [[AFOSession alloc] initWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                         serverTrustManager:trust interceptor:nil redirectHandler:nil
                      cachedResponseHandler:nil eventMonitor:nil];
```

## WebSockets

```objc
// Open via the AFOWebSocket factory (the task's own init isn't exposed to Objective-C).
AFOWebSocketTask *ws = [AFOWebSocket open:[NSURL URLWithString:@"wss://echo.example.com"]];
ws.onText  = ^(NSString *text) { NSLog(@"got: %@", text); };
ws.onClose = ^(NSInteger code, NSData *reason) { NSLog(@"closed: %ld", (long)code); };
[ws resume];
[ws sendText:@"hello" completion:nil];
// ...
[ws closeWithCode:1000 reason:nil];
```

WebSockets run on Apple's native `URLSessionWebSocketTask` (Alamofire's own WebSocket is
experimental `@_spi`), so they don't route through `AFOSession` — `AFOWebSocketTask` owns its
own connection.

> **Note on the facade serializers.** There are no standalone `AFOJSONRequestSerializer` /
> `AFOJSONResponseSerializer` objects — configure behaviour directly on `AFOHTTPSessionManager`
> (`requestEncoding`, `removesKeysWithNullValues`).

## Download a file

```objc
NSURL *destination = [NSURL fileURLWithPath:localPath];
[[session download:@"https://example.com/report.pdf"
             method:AFOHTTPMethodGet
         parameters:nil
           encoding:AFOParameterEncodingURLDefault
            headers:nil
        destination:^NSURL *(NSURL *tempURL, NSHTTPURLResponse *response) { return destination; }]
   responseURL:^(NSURL *fileURL, NSHTTPURLResponse *response, NSError *error) {
       if (!error) NSLog(@"saved to %@", fileURL);
   }];
```

## Automatic retry (exponential backoff)

```objc
AFORetryPolicy *retry = [[AFORetryPolicy alloc] initWithRetryLimit:3
                                          exponentialBackoffBase:2
                                         exponentialBackoffScale:0.5];
AFOSession *session =
  [[AFOSession alloc] initWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                         serverTrustManager:nil interceptor:nil retryPolicy:retry
                            redirectHandler:nil cachedResponseHandler:nil eventMonitor:nil];
```

## Lifecycle — retain your session

`AFOSession` / `AFOHTTPSessionManager` own the underlying connection. **Hold a strong
reference for as long as requests are in flight** — if the session deallocates, its in-flight
requests are cancelled and your completion blocks never fire. Store it as a property, not a
local:

```objc
@property (nonatomic, strong) AFOSession *session;   // ✅ survives the request
// AFOSession.shared also works — it's a long-lived singleton.
```

## Credits

This library is **100% built on [Alamofire](https://github.com/Alamofire/Alamofire)** by the
[Alamofire Software Foundation](https://github.com/Alamofire). `AlamofireObjC` is only a thin
Objective-C bridge — every byte that actually moves over the wire is Alamofire's. All credit for
the networking belongs to them.

- **Alamofire** (the engine, MIT): https://github.com/Alamofire/Alamofire

If `AlamofireObjC` is useful to you, please ⭐ Alamofire too.

## License

**[The Unlicense](https://unlicense.org) — public domain, free for all.** Do anything you want
with this code: copy, modify, ship, sell, no attribution required. Depends on Alamofire (MIT).
