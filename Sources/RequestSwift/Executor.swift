//
//  Executor.swift
//
//
//  Created by Jack Newcombe on 19/10/2023.
//

import Foundation

public protocol Executor {
    func execute(request: Request) async throws -> Response
}

public struct URLSessionExecutor: Executor {
    
    public let session: URLSession
    
    /// Session headers are sent with every request
    public var headers: [String: String] = [:]
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func execute(request: Request) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            let request = enrich(request: request.urlRequest)
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(returning: Response(from: error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: Error.noResponse)
                    return
                }
                let _response = Response(from: httpResponse, responseData: data)
                continuation.resume(returning: _response)
            }.resume()
        }
    }
    
    func enrich(request: URLRequest) -> URLRequest {
        var request = request
        
        headers.forEach { (name, value) in
            request.addValue(value, forHTTPHeaderField: name)
        }
        
        return request
    }
}

extension URLSessionExecutor {
    enum Error: Swift.Error {
        case noResponse
    }
}

extension Request {
    func execute(_ session: URLSession = .shared) async throws -> Response {
        return try await URLSessionExecutor(session: session).execute(request: self)
    }
}

prefix operator <~

prefix func <~(_ request: Request) async throws -> Response {
    return try await request.execute()
}

infix operator <~

public func <~(_ executor: Executor, _ request: Request) async throws -> Response {
    return try await executor.execute(request: request)
}
