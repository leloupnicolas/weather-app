//
//  ForecastTemperatureTableViewCell.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 17/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import Foundation
import UIKit

class ForecastTemperatureTableViewCell: UITableViewCell {
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var temperatureLabel: UILabel!
  
  lazy var timeFormatter: DateFormatter = {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    
    return timeFormatter
  }()
  
  func setData(forecast: Forecast) {
    timeLabel.text = "\(timeFormatter.string(from: forecast.datetime!))"
    temperatureLabel.text = "\(String(format: "%.0f", forecast.floorTemperature - 273.15))°"
  }
}
