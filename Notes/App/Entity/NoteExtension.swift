//
//  NoteExtension.swift
//  Notes
//
//  Created by Артем Куфаев on 02/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

extension Note {
    
    static private func parseColor(json: [String: Double]) -> UIColor? {
        guard let red = json["red"] else { return nil }
        guard let green = json["green"] else { return nil }
        guard let blue = json["blue"] else { return nil }
        guard let alpha = json["alpha"] else { return nil }
        return UIColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }
    
    static func parse(json: [String: Any]) -> Note? {
        
        guard let uid = json["uid"] as? String else { return nil }
        guard let title = json["title"] as? String else { return nil }
        guard let content = json["content"] as? String else { return nil }
        
        // Color
        let color: UIColor
        if let colorDictionary = json["color"] as? [String: Double] {
            guard let parsedColor = parseColor(json: colorDictionary) else { return nil }
            color = parsedColor
        } else {
            color = .white
        }
        
        // Importance
        let importanceInt = (json["importance"] as? Int) ?? 1
        let importance = Note.ImportanceLevels(rawValue: importanceInt)!
        
        // Destruction date
        var destructionDate: Date?
        if let interval = json["destruction_date"] as? Double {
            destructionDate = Date(timeIntervalSince1970: interval)
        } else {
            destructionDate = nil
        }
        
        return Note(uid: uid, title: title, content: content, color: color, importance: importance, destructionDate: destructionDate)
        
    }
    
    private func parseColor(_ color: UIColor) -> [String: Double] {
        var nColor: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
        nColor.red = 0.0; nColor.green = 0.0; nColor.blue = 0.0; nColor.alpha = 0.0
        color.getRed(&nColor.red, green: &nColor.green, blue: &nColor.blue, alpha: &nColor.alpha)
        
        var colorDic = [String: Double]()
        colorDic["red"] = Double(nColor.red)
        colorDic["green"] = Double(nColor.green)
        colorDic["blue"] = Double(nColor.blue)
        colorDic["alpha"] = Double(nColor.alpha)
        return colorDic
    }
    
    var json: [String: Any] {
        var json = [String: Any]()
        json["uid"] = uid
        json["title"] = title
        json["content"] = content
        
        if color != .white {
            json["color"] = parseColor(self.color)
        }
        
        if (self.importance != .usual) {
            json["importance"] = self.importance.rawValue
        }
        json["destruction_date"] = self.destructionDate?.timeIntervalSince1970
        
        return json
    }
    
}
