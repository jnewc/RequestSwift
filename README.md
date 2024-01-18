# RequestSwift

```swift
let response = «Request(url: "https://epic.lol", method: .get {
    Query(key: "very", value: "nice")
}

response.status   // 200
response.headers  // [ 'content-type': 'application/json', ... ]
response.error    // nil | RequestError
response.data     // e.g. JSONDecoder.decode(SpySecrets.self, response.data!)
```

or 

```swift
let result = Request(url: "https://epic.lol", method: .get {
    Query(key: "very", value: "nice")
} ~> SpySecrets.self

result.response   // status, headers, error, data ...
result.body       // e.g. print(result.body.secretMessage")

```
