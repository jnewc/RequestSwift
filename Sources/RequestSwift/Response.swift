//
//  Response.swift
//
//
//  Created by Jack Newcombe on 19/10/2023.
//

import Foundation

public struct Response {
    
    public let status: Int
    
    public let headers: [String: String]
    
    public let error: Error?
    
    public let data: Data?
    
    init(from httpResponse: HTTPURLResponse, responseData: Data?) {
        status = httpResponse.statusCode
        headers = httpResponse.allHeaderFields.compactMap { key, value in
            guard let name = key as? String, let value = value as? String else {
                return nil
            }
            return (name, value)
        }
        data = responseData
        error = nil
    }
    
    init(from error: Error) {
        self.error = error
        status = 0
        data = nil
        headers = [:]
    }
    
}

extension Dictionary {
    
    typealias Mapper<K, V> = (Key, Value) -> (K, V)?
    
    func compactMap<K, V>(_ completion: Mapper<K, V>) -> Dictionary<K, V> where K: Hashable {
        return reduce(into: [K: V]()) { result, next in
            guard let value = completion(next.key, next.value) else {
                return
            }
            result[value.0] = value.1
        }
    }
    
}
