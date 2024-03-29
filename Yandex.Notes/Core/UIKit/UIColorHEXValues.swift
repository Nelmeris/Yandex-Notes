//
//  UIColorHEXValues.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hexString: String) {
        let hexString: NSString =
            (hexString as NSString).trimmingCharacters(
                in: NSCharacterSet.whitespacesAndNewlines
                ) as NSString
        let scanner = Scanner(string: hexString as String)
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        r = r >= 0 ? r : 0
        g = g >= 0 ? g : 0
        b = b >= 0 ? b : 0
        a = a >= 0 ? a : 0
        let rgb: Int =
            (Int)(r * 255) << 16 |
            (Int)(g * 255) << 8  |
            (Int)(b * 255) << 0
        return NSString(format:"#%06x", rgb) as String
    }
    
}
