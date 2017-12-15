//
//  ForecastsRepository.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Need
import CoreData

typealias FormattedForecasts = [String: [Forecast]]

enum ForecastRepositoryError: Error {
  case missingTemperature
  case missingMeanWind
}

protocol ForecastsRepository {
  func fetchRemotely(forLatitude latitude: Double, andLongitude longitude: Double, completion: @escaping (FormattedForecasts) -> Void)
  func fetchLocally(completion: @escaping ([Forecast]) -> Void)
  func deserialize(forDate date: Date, latitude: Double, longitude: Double, data: JSON) -> Forecast?
}

class DefaultForecastsRepository: ServicesInjectionAware {
  lazy var dateTimeFormatter: DateFormatter = {
    let dateTimeFormatter = DateFormatter()
    dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    return dateTimeFormatter
  }()

  lazy var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    return dateFormatter
  }()
}

extension DefaultForecastsRepository: ForecastsRepository {
  func fetchRemotely(forLatitude latitude: Double, andLongitude longitude: Double, completion: @escaping (FormattedForecasts) -> Void) {
    Alamofire.request(self.formatUrl(forLatitude: latitude, andLongitude: longitude), method: .get).validate().responseJSON { response in
      switch response.result {
      case .success(let value):
        let json = JSON(value)

        var entities: [Forecast] = []
        for (key, data) in json {
          guard let existingDate = self.deserializeDate(date: key) else {
            continue
          }
          
          guard let consistentEntity = self.deserialize(forDate: existingDate, latitude: latitude, longitude: longitude, data: data) else {
            continue
          }

          entities.append(consistentEntity)
        }

        // TODO handle local storage saving
        
        completion(self.formatData(entities: entities))

      case .failure(let error):
        print(error)
        completion([:])
      }
    }
  }

  func fetchLocally(completion: @escaping ([Forecast]) -> Void) {
    // TODO
  }

  func deserialize(forDate date: Date, latitude: Double, longitude: Double, data: JSON) -> Forecast? {
    guard let temperature = data["temperature"]["sol"].double else {
      return nil
    }

    guard let meanWind = data["vent_moyen"]["10m"].double else {
      return nil
    }

    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        return nil
    }
    let managedContext = appDelegate.persistentContainer.viewContext
    
    let entity = NSEntityDescription.entity(forEntityName: "Forecast", in: managedContext)!
    let forecast = NSManagedObject(entity: entity, insertInto: managedContext)
    forecast.setValue(date, forKey: "datetime")
    forecast.setValue(meanWind, forKey: "meanWind")
    forecast.setValue(temperature, forKey: "floorTemperature")
    forecast.setValue(latitude, forKey: "latitude")
    forecast.setValue(longitude, forKey: "longitude")
    
    return forecast as? Forecast
  }

  private func formatUrl(forLatitude latitude: Double, andLongitude longitude: Double) -> String {
    return "https://www.infoclimat.fr/public-api/gfs/json?_ll=\(latitude),\(longitude)&_auth=UkgFElUrVnRTfgcwAXcAKQJqDzoPeQUiUy8HZFs%2BB3oAawRlAmJTNV4wVypSfVFnBSgObQ80BDRROgF5Xy0HZlI4BWlVPlYxUzwHYgEuACsCLA9uDy8FIlMxB2lbNQd6AGEEZQJiUy9eN1c0UnxRZAU3DmYPLwQjUTMBY18zB2dSMgVlVTZWNVM9B2ABLgArAjQPPg8zBT5TYgczW2IHZwBiBGYCYlNkXmdXNlJ8UWcFMA5uDzkEP1E3AWZfMQd7Ui4FGFVFVilTfAcnAWQAcgIsDzoPbgVp&_c=a70e327597460269ee0853b1ca78c9ba"
  }
  
  private func deserializeDate(date: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    if let validDate = dateFormatter.date(from: date) {
      return validDate
    }

    return nil
  }

  private func formatData(entities: [Forecast]) -> FormattedForecasts {
    var formattedData: FormattedForecasts = [:]

    for entity in entities {
      let index = dateFormatter.string(from: entity.datetime!)
      if nil == formattedData[index] {
        formattedData[index] = []
      }
      
      formattedData[index]?.append(entity)
    }
    
    return formattedData
  }
}
