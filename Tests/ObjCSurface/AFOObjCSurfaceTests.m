@import XCTest;
@import AlamofireObjC;

/// The most important guarantee: every public type compiles and is callable from PURE
/// Objective-C. If any symbol weren't `@objc`-exposed, this file would fail to build.
///
/// Runs under the CocoaPods `Tests` test_spec / an Xcode test target (NOT swift test — SPM
/// targets are single-language).
@interface AFOObjCSurfaceTests : XCTestCase
@end

@implementation AFOObjCSurfaceTests

- (void)testChainableCoreIsCallable {
    AFOSession *session = AFOSession.shared;
    XCTAssertNotNil(session);

    AFORequest *request = [session request:@"https://example.com"
                                    method:AFOHTTPMethodGet
                                parameters:nil
                                  encoding:AFOParameterEncodingURLDefault
                                   headers:@{@"X-Token": @"abc"}];
    XCTAssertNotNil(request);
    [[request validate] responseJSON:^(AFOResponse *response) { (void)response.value; }];
}

- (void)testMultipartBuilderIsCallable {
    AFOMultipartFormData *form = [AFOMultipartFormData new];
    [form appendData:[@"x" dataUsingEncoding:NSUTF8StringEncoding] name:@"field"];
    [form appendData:[@"y" dataUsingEncoding:NSUTF8StringEncoding]
                name:@"userfile" fileName:@"i.jpg" mimeType:@"image/jpeg"];
    XCTAssertNotNil(form);
}

- (void)testUploadOperationIsCallable {
    AFOSession *session = AFOSession.shared;
    AFOMultipartFormData *form = [AFOMultipartFormData new];
    AFORequestOperation *op =
        [AFOUploadOperation multipartOperationWithSession:session
                                                     form:form
                                                URLString:@"https://example.com/upload"
                                                   method:AFOHTTPMethodPost
                                                  headers:nil
                                                 userInfo:@{@"pinID": @42}
                                                 progress:^(NSProgress *p) { (void)p; }
                                                  success:^(NSURLSessionTask *t, id obj, id userInfo) { (void)userInfo; }
                                                  failure:^(NSURLSessionTask *t, NSError *e, id userInfo) { (void)e; }];
    XCTAssertNotNil(op);
}

- (void)testFacadeIsCallable {
    AFOHTTPSessionManager *manager =
        [AFOHTTPSessionManager managerWithBaseURL:[NSURL URLWithString:@"https://example.com"]];
    manager.requestEncoding = AFOParameterEncodingJSON;
    manager.removesKeysWithNullValues = YES;
    manager.defaultHeaders = @{@"X-Token": @"abc"};
    XCTAssertNotNil(manager);
    [manager get:@"/users" parameters:nil headers:nil progress:nil
         success:^(NSURLSessionTask *t, id obj) { (void)obj; }
         failure:^(NSURLSessionTask *t, NSError *e) { (void)e; }];
}

- (void)testErgonomicsSurfaceIsCallable {
    AFOSession *session = AFOSession.shared;

    // Per-request interceptor + timeout, chained, with typed accessors + error category.
    [[session request:@"https://example.com"
               method:AFOHTTPMethodGet
           parameters:nil
             encoding:AFOParameterEncodingURLDefault
              headers:nil
              timeout:30
          interceptor:[AFOInterceptor headerInjector:@"X-T" value:@"1"]]
     responseJSON:^(AFOResponse *response) {
         NSDictionary *dict = response.jsonDictionary;
         NSArray *arr = response.jsonArray;
         NSString *str = response.stringValue;
         (void)dict; (void)arr; (void)str;
         AFOErrorCode code = response.error.afoErrorCode;
         if (code == AFOErrorCodeExplicitlyCancelled || response.error.afoIsCancelled) { return; }
         NSInteger status = response.error.afoStatusCode;
         (void)status;
     }];

    // Model-mapper hook.
    [[session get:@"https://example.com" headers:nil]
     responseObjectWithMap:^id _Nullable(id json) { return json; }
                   handler:^(id model, AFOResponse *response) { (void)model; (void)response; }];

    [session cancelAllRequests];
    XCTAssertNotNil(session);
}

- (void)testWebSocketSurfaceIsCallable {
    AFOWebSocketTask *ws = [AFOWebSocket open:[NSURL URLWithString:@"ws://example.com"]];
    ws.onText = ^(NSString *text) { (void)text; };
    ws.onBinary = ^(NSData *data) { (void)data; };
    ws.onClose = ^(NSInteger code, NSData *reason) { (void)code; (void)reason; };
    ws.onError = ^(NSError *error) { (void)error; };
    [ws sendText:@"hi" completion:^(NSError *e) { (void)e; }];
    [ws sendData:[NSData data] completion:nil];
    [ws sendPing:nil];
    [ws closeWithCode:1000 reason:nil];
    XCTAssertNotNil(ws);
}

- (void)testRetryPolicySurfaceIsCallable {
    AFORetryPolicy *policy = [[AFORetryPolicy alloc] initWithRetryLimit:3
                                                exponentialBackoffBase:2
                                               exponentialBackoffScale:0.5];
    AFOSession *session =
        [[AFOSession alloc] initWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                               serverTrustManager:nil interceptor:nil retryPolicy:policy
                                  redirectHandler:nil cachedResponseHandler:nil eventMonitor:nil];
    XCTAssertNotNil(session);
}

- (void)testPinningTypesAreCallable {
    AFOServerTrustPolicy *policy =
        [AFOServerTrustPolicy pinnedCertificates:@[]
                                acceptSelfSigned:NO
                        performDefaultValidation:YES
                                    validateHost:YES];
    AFOServerTrustManager *trust =
        [[AFOServerTrustManager alloc] initWithPolicies:@{@"example.com": policy}
                                allHostsMustBeEvaluated:NO];
    XCTAssertNotNil(trust);
}

@end
