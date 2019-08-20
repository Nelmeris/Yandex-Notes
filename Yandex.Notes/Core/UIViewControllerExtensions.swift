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
    
    func shortDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "HH:mm"
            return "Today, \(dateFormatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            dateFormatter.dateFormat = "HH:mm"
            return "Tomorrow, \(dateFormatter.string(from: date))"
        } else if calendar.isDateInWeekend(date) {
            dateFormatter.dateFormat = "EEE, HH:mm"
            return dateFormatter.string(from: date)
        } else {
            dateFormatter.dateFormat = "d, MMMM"
            return dateFormatter.string(from: date)
        }
    }
    
}
