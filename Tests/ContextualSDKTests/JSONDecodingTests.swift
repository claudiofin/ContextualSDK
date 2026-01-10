//
//  JSONDecodingTests.swift
//  ContextualSDKTests
//
//  Created by Antigravity on 10/01/26.
//

import XCTest
@testable import ContextualSDK

final class JSONDecodingTests: XCTestCase {

    func testDecodeMapStrategy() throws {
        let json = """
        {
            "strategy": "map",
            "label": "Home Address",
            "map": {
                "showUserLocation": true,
                "initialRegion": [45.0, 9.0, 0.1, 0.1]
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decision = try JSONDecoder().decode(InputDecision.self, from: data)
        
        XCTAssertEqual(decision.strategy, .map)
        XCTAssertEqual(decision.label, "Home Address")
        XCTAssertNotNil(decision.map)
        XCTAssertTrue(decision.map!.showUserLocation)
        XCTAssertEqual(decision.map!.initialRegion?.count, 4)
        XCTAssertEqual(decision.map!.initialRegion?[0], 45.0)
    }
    
    func testDecodeNativeStrategy() throws {
        let json = """
        {
            "strategy": "native",
            "label": "Rating",
            "native": {
                "control": "slider",
                "range": [1, 5, 1],
                "unit": "stars"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decision = try JSONDecoder().decode(InputDecision.self, from: data)
        
        XCTAssertEqual(decision.strategy, .native)
        XCTAssertEqual(decision.native?.control, "slider")
        XCTAssertEqual(decision.native?.range, [1, 5, 1])
    }
}
