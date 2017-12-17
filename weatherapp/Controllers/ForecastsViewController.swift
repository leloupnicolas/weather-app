//
//  ViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import UIKit
import PKHUD
import CoreLocation

class ForecastsViewController: BaseViewController {
  let defaultCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 48.85341, longitude: 2.3488)
  var currentCoordinates: CLLocationCoordinate2D! {
    didSet {
      if !isDefaultLocation {
        refreshData()
      }
    }
  }
  var isDefaultLocation = true {
    didSet {
      locationSourceChanged()
    }
  }
  var chosenIndex: String!
  
  @IBOutlet weak var tableView: UITableView!
  var locationActionSheet: UIAlertController!
  
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
  
  var locationManager: CLLocationManager!

  override func viewDidLoad() {
    super.viewDidLoad()

    initActionSheet()
    initCoreLocation()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    refreshData()
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
  
  private func refreshData() {
    var coordinateToUse = defaultCoordinates
    if let userCurrentCoordinate = currentCoordinates, !isDefaultLocation {
      coordinateToUse = userCurrentCoordinate
    }
    
    HUD.show(.progress)
    forecastsRepository.fetchRemotely(forLatitude: coordinateToUse.latitude, andLongitude: coordinateToUse.longitude) { (forecasts) in
      HUD.hide()
      self.forecasts = forecasts
    }
  }
  
  private func initActionSheet() {
    locationActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
    locationActionSheet.addAction(cancelAction)
    let defaultLocationAction = UIAlertAction(title: "Use default location", style: .default) { (_) in
      self.isDefaultLocation = true
    }
    locationActionSheet.addAction(defaultLocationAction)
    let currentLocationAction = UIAlertAction(title: "Use current location", style: .default) { (_) in
      self.isDefaultLocation = false
    }
    locationActionSheet.addAction(currentLocationAction)
    locationActionSheet.popoverPresentationController?.delegate = self
  }
  
  private func initCoreLocation() {
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
  }
  
  private func refreshUI() {
    tableView.reloadData()
    self.title = isDefaultLocation ? "Default location" : "Current location"
  }

  private func locationSourceChanged() {
    if isDefaultLocation {
      refreshData()
    } else {
      locationManager.requestAlwaysAuthorization()
      
      if CLLocationManager.locationServicesEnabled() {
        locationManager.startUpdatingLocation()
      }
    }
  }
  
  @IBAction func editButtonTapped(_ sender: Any) {
    self.present(locationActionSheet, animated: true)
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

extension ForecastsViewController: UIPopoverPresentationControllerDelegate {
  public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
    popoverPresentationController.sourceView = self.view
    popoverPresentationController.sourceRect = self.view.bounds
  }
}

extension ForecastsViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let userLocation:CLLocation = locations[0] as CLLocation
    
    manager.stopUpdatingLocation()
    
    currentCoordinates = userLocation.coordinate
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
  {
    print("Error \(error)")
  }
}
