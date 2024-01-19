//
//  Executor.swift
//
//
//  Created by Jack Newcombe on 19/10/2023.
//

import Foundation

protocol Executor {
    func execute(request: Request) async throws -> Response
}

public struct URLSessionExecutor: Executor {
    
    public let session: URLSession
    
    public func execute(request: Request) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request.urlRequest) { data, response, error in
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
