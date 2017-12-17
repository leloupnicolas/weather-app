//
//  DefaultForecastsRepositoryTest.swift
//  weatherappTests
//
//  Created by Nicolas LELOUP on 17/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import weatherapp

class DefaultForecastsRepositoryTest: XCTestCase {
  var forecastRepository: DefaultForecastsRepository!
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    forecastRepository = DefaultForecastsRepository()
  }
  
  override func tearDown() {
    forecastRepository = nil
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testFetchRemotely() {
    // wrong coordinates test
    let wrongCoordinateTestPromise = expectation(description: "No results for wrong coordinate")
    forecastRepository.fetchRemotely(forLatitude: 424.242, andLongitude: 424.242) { forecasts in
      if 0 == forecasts.count {
        wrongCoordinateTestPromise.fulfill()
      } else {
        XCTFail()
      }
    }

    // Paris coordinates test
    let rightCoordinateTestPromise = expectation(description: "Results for right coordinate")
    forecastRepository.fetchRemotely(forLatitude: 48.85341, andLongitude: 2.3488) { forecasts in
      if 0 == forecasts.count {
        XCTFail()
      } else {
        rightCoordinateTestPromise.fulfill()
      }
    }
    
    waitForExpectations(timeout: 5, handler: nil)
  }

  func testDeserialize() {
    // json from the API with errors added
    let json = "{\"request_state\":200,\"request_key\":\"fd543c77e33d6c8a5e218e948a19e487\",\"message\":\"OK\",\"model_run\":\"01\",\"source\":\"internal:GFS:1\",\"2017-12-17 04:00:00\":{\"temperature\":{\"2m\":276.5,\"sol\":\"wrong_value\"},\"vent_moyen\":{\"10m\":5}},\"2017-12-17 07:00:00\":{\"temperature\":{\"2m\":276.5,\"sol\":\"wrong_value\"},\"vent_moyen\":{\"10m\":5}},\"17/12/2017 10:00:00\":{\"temperature\":{\"2m\":276.5,\"sol\":277},\"vent_moyen\":{\"10m\":5}},\"2017-12-17 13:00:00\":{\"temperature\":{\"2m\":276.5,\"sol\":277},\"vent_moyen\":{\"10m\":\"wrong_value\"}},\"2017-12-18 04:00:00\":{\"temperature\":{\"2m\":276.5,\"sol\":277.0},\"vent_moyen\":{\"10m\":5}}}"

    let forecasts = forecastRepository.deserialize(forLatitude: 48.85341, andLongitude: 2.3488, json: JSON(parseJSON: json))

    XCTAssertEqual(1, forecasts.keys.count)
    XCTAssertEqual(1, forecasts[forecasts.keys.first!]!.count)
  }
}
