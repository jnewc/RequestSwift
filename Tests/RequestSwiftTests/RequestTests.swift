//
//  RequestTests.swift
//
//
//  Created by Jack Newcombe on 16/10/2023.
//

import XCTest
@testable import RequestSwift

class RequestTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    var testRequest: Request {
        try!
        Request(url: "https://newcombe.io", method: .post) {
            Header(key: "Test2", value: "Val2")
            Query(key: "test3", value: "val3")
            Body { .text(text: "Test") }
        }
    }
    
    func testRequestCreation() async throws {
        let request = testRequest
        let urlRequest = request.urlRequest
        XCTAssertEqual(urlRequest.allHTTPHeaderFields!["Test2"], "Val2")
        XCTAssertEqual(urlRequest.url?.absoluteString.components(separatedBy: "?").first, "https://newcombe.io")
        XCTAssertEqual(urlRequest.httpBody?.string, "Test")
        
        let response = try await «request
        
        XCTAssertNil(response.error)
    }
}

extension Data {
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}
