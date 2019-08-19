//
//  VisibleViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

extension UIWindow {
    
    private func getVisibleViewController(on base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
            let visible = nav.visibleViewController
            return getVisibleViewController(on: visible)
        }
        
        if let tab = base as? UITabBarController,
            let selected = tab.selectedViewController {
            return getVisibleViewController(on: selected)
        }
        
        if let presented = base?.presentedViewController {
            return getVisibleViewController(on: presented)
        }
        
        return base
    }
    
    var visibleViewController: UIViewController? {
        let base = self.rootViewController
        return getVisibleViewController(on: base)
    }
    
}
