//
//  ViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import UIKit
import PKHUD

class ForecastsViewController: BaseViewController {
  let defaultLatitude = 48.85341
  let defaultLongitude = 2.3488
  var isDefaultLocation = true
  var chosenIndex: String!
  
  @IBOutlet weak var tableView: UITableView!
  
  var forecasts: FormattedForecasts = [:] {
    didSet {
      orderedForecastsIndices = Array(forecasts.keys).sorted(by: <)
      refreshUI()
    }
  }
  var orderedForecastsIndices: [String] = []
  
  lazy var forecastsRepository: ForecastsRepository = {
    return getService()!
  }()

  lazy var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    return dateFormatter
  }()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    HUD.show(.progress)
    forecastsRepository.fetchRemotely(forLatitude: defaultLatitude, andLongitude: defaultLongitude) { (forecasts) in
      HUD.hide()
      self.forecasts = forecasts
    }
  }
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if "FORECASTS_TO_DETAILS_SEGUE" == identifier {
      return nil != chosenIndex
    } else {
      return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if "FORECASTS_TO_DETAILS_SEGUE" == segue.identifier {
      if let destinationViewController = segue.destination as? ForecastViewController {
        destinationViewController.dateAsString = chosenIndex
        destinationViewController.forecasts = forecasts[chosenIndex]
      }
    }
    
    super.prepare(for: segue, sender: sender)
  }
  
  private func refreshUI() {
    tableView.reloadData()
    self.title = isDefaultLocation ? "Default location" : "Current location"
  }
}

extension ForecastsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return forecasts.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell = tableView.dequeueReusableCell(
      withIdentifier: "WEATHER_DAY_CELL",
      for: indexPath
    )

    let stringDate = orderedForecastsIndices[indexPath.row]
    let concernedDate: Date = dateFormatter.date(from: stringDate)!
    
    if Calendar.current.isDateInToday(concernedDate) {
      cell.textLabel?.text = "Today"
    } else if Calendar.current.isDateInYesterday(concernedDate) {
      cell.textLabel?.text = "Yesterday"
    } else if Calendar.current.isDateInTomorrow(concernedDate) {
      cell.textLabel?.text = "Tomorrow"
    } else {
      cell.textLabel?.text = dateFormatter.string(from: concernedDate)
    }
    
    return cell
  }
}

extension ForecastsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    chosenIndex = orderedForecastsIndices[indexPath.row]
    if self.shouldPerformSegue(withIdentifier: "FORECASTS_TO_DETAILS_SEGUE", sender: self) {
      self.performSegue(withIdentifier: "FORECASTS_TO_DETAILS_SEGUE", sender: self)
    }
  }
}

