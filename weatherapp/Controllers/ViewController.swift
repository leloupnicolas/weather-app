//
//  ViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import UIKit
import PKHUD

class ViewController: BaseViewController {
  let defaultLatitude = 48.85341
  let defaultLongitude = 2.3488
  
  var forecasts: [Forecast] = [] {
    didSet {
      
    }
  }
  
  lazy var forecastsRepository: ForecastsRepository = {
    return getService()!
  }()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    HUD.show(.progress)
    forecastsRepository.fetchRemotely(forLatitude: defaultLatitude, andLongitude: defaultLongitude) { (forecasts) in
      HUD.hide()
      print(forecasts.count)
    }
  }
}

