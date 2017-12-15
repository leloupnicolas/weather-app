//
//  BaseViewController.swift
//  weatherapp
//
//  Created by Nicolas LELOUP on 15/12/2017.
//  Copyright © 2017 leloupnicolas. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UIViewController {
  func getService<T>() -> T? {
    guard let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return nil
    }
    
    return appDelegate.serviceLocator.getService()
  }
}
