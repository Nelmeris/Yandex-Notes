//
//  NoteExtension.swift
//  Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

// MARK: - Parse from JSON
extension Note {
    
    static func parse(json: [String: Any]) -> Note? {
        
        guard let uid = json["uid"] as? String,
            let title = json["title"] as? String,
            let content = json["content"] as? String,
            let createDateDouble = json["create_date"] as? Double else { return nil }
        
        let createDate = Date(timeIntervalSince1970: createDateDouble)
        
        // Color
        var color: UIColor
        if let hexColor = json["color"] as? String {
            color = UIColor(hexString: hexColor)
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
        
        return Note(uid: uid, title: title, content: content, color: color, importance: importance, destructionDate: destructionDate, createdDate: createDate)
        
    }
    
    private init(
        uid: String = UUID().uuidString,
        title: String, content: String, color: UIColor = .white,
        importance: ImportanceLevels,
        destructionDate selfDestructionDate: Date? = nil,
        createdDate: Date
        ) {
        self.uid = uid
        self.title = title
        self.content = content
        self.color = color
        self.importance = importance
        self.destructionDate = selfDestructionDate
        self.createDate = createdDate
    }
    
}

// MARK: - Parse to JSON
extension Note {
    
    var json: [String: Any] {
        var json = [String: Any]()
        json["uid"] = uid
        json["title"] = title
        json["content"] = content
        
        if color != .white {
            json["color"] = color.toHexString()
        }
        
        if (self.importance != .usual) {
            json["importance"] = self.importance.rawValue
        }
        
        json["destruction_date"] = self.destructionDate?.timeIntervalSince1970
        
        json["create_date"] = self.createDate.timeIntervalSince1970
        
        return json
    }
    
}
