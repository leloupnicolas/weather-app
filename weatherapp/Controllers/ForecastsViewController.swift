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

// MARK: Class
/// Forecasts View Controller: displays a table view with forecasts by days
class ForecastsViewController: BaseViewController {
  // MARK: data variables
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
  
  // MARK: UI variables
  @IBOutlet weak var tableView: UITableView!
  var locationActionSheet: UIAlertController!
  
  // MARK: services and utils variables
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

  // MARK: Overridden methods
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
  
  // MARK: Private own methods
  /**
   Fetches forecasts data, remotely or locally.
   */
  private func refreshData() {
    if !isDataAlreadyLoaded {
      isDataAlreadyLoaded = true
      var coordinateToUse = defaultCoordinates
      if let userCurrentCoordinate = currentCoordinates, !isDefaultLocation {
        coordinateToUse = userCurrentCoordinate
      }
      
      HUD.show(.progress)
      forecastsRepository.fetchLocally(forLatitude: coordinateToUse.latitude, andLongitude: coordinateToUse.longitude) { (localForecasts) in
        if 0 < localForecasts.count {
          HUD.hide()
          self.forecasts = localForecasts
        } else {
          self.forecastsRepository.fetchRemotely(forLatitude: coordinateToUse.latitude, andLongitude: coordinateToUse.longitude) { (remoteForecasts) in
            HUD.hide()
            self.forecasts = remoteForecasts
          }
        }
      }
    }
  }
  
  /**
   Prepares location source action sheet.
   */
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
  
  /**
   Prepares Core Location uses.
   */
  private func initCoreLocation() {
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
  }
  
  /**
   Refreshes user interface, reloading table view content and updating controller title.
   */
  private func refreshUI() {
    tableView.reloadData()
    self.title = isDefaultLocation ? "Default location" : "Current location"
  }

  /**
   Fired when location source flag changed. Handles user permissions asking and data fetching.
   */
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
