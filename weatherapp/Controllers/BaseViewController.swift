//
//  BaseViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import Foundation
import UIKit

// MARK: Class
/// Base View Controller which gathers common view controllers needs.
class BaseViewController: UIViewController {
  /**
   Flag to store wether data has already been loaded during navigation
   */
  var isDataAlreadyLoaded: Bool = false
  
  /**
   Retrieves the registered service of type T from the LazyServiceLocator.
   
   - Returns:  The registered instance.
   */
  func getService<T>() -> T? {
    guard let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return nil
    }
    
    return appDelegate.serviceLocator.getService()
  }
}
