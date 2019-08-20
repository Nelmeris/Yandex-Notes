//
//  UIViewControllerExtensions.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 20/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(with title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "ОК", style: .cancel)
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }
    
}
