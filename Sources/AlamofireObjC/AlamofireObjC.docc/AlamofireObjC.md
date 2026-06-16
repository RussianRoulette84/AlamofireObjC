# ``AlamofireObjC``

Use [Alamofire](https://github.com/Alamofire/Alamofire) 5 from pure Objective-C.

## Overview

`AlamofireObjC` is an `@objc` bridge over Alamofire. It ships two layers that share one engine:

- A **chainable core** — ``AFOSession`` vends ``AFORequest``, ``AFOUploadRequest``,
  ``AFODownloadRequest`` and ``AFODataStreamRequest``, each delivering an ``AFOResponse``.
- An **AFNetworking-compatible facade** — ``AFOHTTPSessionManager`` for near drop-in migration
  off the deprecated AFNetworking.

> Important: `AFOSession`/`AFOHTTPSessionManager` own the connection. Retain a strong reference
> while requests are in flight, or they are cancelled and your completion blocks never fire.

## Topics

### Core

- ``AFOSession``
- ``AFORequest``
- ``AFOUploadRequest``
- ``AFODownloadRequest``
- ``AFODataStreamRequest``
- ``AFOResponse``
- ``AFOMultipartFormData``
- ``AFOWebSocketTask``

### Configuration

- ``AFOHTTPMethod``
- ``AFOParameterEncoding``
- ``AFOValidationConfig``
- ``AFOInterceptor``
- ``AFORetryPolicy``
- ``AFOEventMonitor``
- ``AFORedirectHandler``
- ``AFOCachedResponseHandler``

### Security

- ``AFOServerTrustPolicy``
- ``AFOServerTrustManager``

### Errors

- ``AFOError``
- ``AFOErrorCode``

### Operations

- ``AFOAsynchronousOperation``
- ``AFORequestOperation``
- ``AFOUploadOperation``
- ``AFODownloadOperation``

### AFNetworking-compatible facade

- ``AFOHTTPSessionManager``
- ``AFOSecurityPolicy``
- ``AFOReachabilityManager``
