//
//  Request.swift
//
//
//  Created by Jack Newcombe on 15/10/2023.
//

import Foundation
import SwiftUI

infix operator ~>

public struct Parsed<T> {
    public let body: T
    public let response: Response
}

let jsonDecoder = JSONDecoder()

public func ~><T: Decodable>(_ request: Request, _ type: T.Type) async throws -> Parsed<T> {
    let response = try await <~request
    guard let data = response.data else {
        throw RequestError.unableToDecodeBody
    }
    let body = try jsonDecoder.decode(T.self, from: data)
    
    return Parsed(body: body, response: response)
}


private func queryString(from components: [RequestComponent]) -> String {
    return components.compactMap { $0 as? Query }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
}

public struct Request {
    public let url: URL
    public let method: Method
    public let components: [RequestComponent]
    
    public init(url: String,
         method: Method = .get,
         @ComponentsBuilder _ components: () -> [RequestComponent]) throws {
        let components = components()
        guard let url = URL(string: "\(url)?\(queryString(from: components))") else {
            throw RequestError.invalidURL
        }
        self.url = url
        self.method = method
        self.components = components
    }
    
    public var headers: [Header] {
        let collectedHeaders = components.compactMap { $0 as? HeaderCollection }
            .map { $0.headers.map { Header(key: $0.key, value: $0.value) } }
            .joined()
        return components.compactMap { $0 as? Header } + collectedHeaders
    }
    
    public var queryItems: [Query] {
        let collectedQuery = components.compactMap { $0 as? QueryCollection }
            .map { $0.items.map { Query(key: $0.key, value: $0.value) } }
            .joined()
        return components.compactMap { $0 as? Query } + collectedQuery
    }
    
    public var body: Data? {
        guard let body = components.compactMap({ $0 as? Body }).first else {
            return nil
        }
        
        switch body.body() {
        case .json(let encodable):
            return try? JSONEncoder().encode(encodable)
        case .text(let text):
            return text.data(using: .utf8)
        }
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.value
        headers.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpBody = body
        return request
    }
}

public protocol RequestComponent {}

extension RequestComponent {
    public func header(key: String, value: String) -> Header {
        return .init(key: key, value: value)
    }
    
    public func query(key: String, value: String) -> Query {
        return .init(key: key, value: value)
    }
    
    public func body(body: @escaping () -> BodyType) -> Body {
        return .init(body: body)
    }
}

public enum Method: String {
    case get = "GET"
    case post = "POST"
    
    public var value: String { rawValue }
}

public struct Header: RequestComponent {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct HeaderCollection: RequestComponent {
    
    let headers: [String: String]
    
    public init(headers: [String: String]) {
        self.headers = headers
    }
}

public struct Query: RequestComponent {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

}

public struct QueryCollection: RequestComponent {
    
    let items: [String: String]
    
    public init(items: [String: String]) {
        self.items = items
    }
}

public struct Body: RequestComponent {
    public let body: () -> BodyType
    
    public init(body: @escaping () -> BodyType) {
        self.body = body
    }
}

public enum BodyType {
    case json(encodable: Encodable)
    case text(text: String)
}

public enum RequestError: Swift.Error {
    case multipleBodiesFound
    case invalidURL
    case unableToDecodeBody
}

extension Request {
    @resultBuilder
    public struct ComponentsBuilder {
        public static func buildBlock<each T>(_ components: repeat each T) -> [RequestComponent] where repeat each T: RequestComponent {
            var array: [RequestComponent] = []
            (repeat(array.append(each components)))
            return array
        }
    }
}
