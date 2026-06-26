# Changelog

## 5.12.2

- **Fix (crash):** `post`/`put`/`patch`/`delete` now accept a **top-level JSON array** body, not
  only a dictionary. AFNetworking accepted `id`; the first port narrowed the body to
  `[String: Any]`, so passing an `NSArray` crashed while bridging to a Swift dictionary
  (`-[__NSArrayM _getObjects:andKeys:count:]: unrecognized selector`). Array and dictionary
  bodies now both serialise correctly; dictionary behaviour is unchanged.
- The body argument on the verb methods and on `AFORequestOperation.operation` is now `id`
  (`Any?`) for full AFNetworking parity. Added `AFOSession.requestJSONObject:` which encodes any
  JSON object via `JSONEncoding`. A non-serialisable body fails the request instead of crashing.

## 5.12.1

- GET/HEAD always URL-encode their parameters (Alamofire rejects a body on GET), fixing the
  Google address autocomplete regression after the AFNetworking migration.
