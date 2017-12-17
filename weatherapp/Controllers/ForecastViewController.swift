//
//  ForecastViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import Foundation
import UIKit

class ForecastViewController: BaseViewController {
  var forecasts: [Forecast]!
  var dateAsString: String!
  
  @IBOutlet weak var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let _ = forecasts, 0 < forecasts.count else {
      self.navigationController?.popViewController(animated: true)
      return
    }
    
    self.title = dateAsString
    
    forecasts.sort { (lhs, rhs) -> Bool in
      return lhs.datetime! < rhs.datetime!
    }
    
    tableView.reloadData()
  }
}

extension ForecastViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return forecasts.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: ForecastTemperatureTableViewCell = tableView.dequeueReusableCell(
      withIdentifier: "FORECAST_ENTRY",
      for: indexPath
    ) as! ForecastTemperatureTableViewCell
    
    cell.setData(forecast: forecasts[indexPath.row])
    
    return cell
  }
}

extension ForecastViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
}
