//
//  GlobalMethods.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

func getVisibleViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
        let visible = nav.visibleViewController
        return getVisibleViewController(base: visible)
    }
    
    if let tab = base as? UITabBarController,
        let selected = tab.selectedViewController {
        return getVisibleViewController(base: selected)
    }
    
    if let presented = base?.presentedViewController {
        return getVisibleViewController(base: presented)
    }
    
    return base
}
