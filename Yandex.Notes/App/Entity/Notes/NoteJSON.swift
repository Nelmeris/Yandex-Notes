//
//  NoteExtension.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

// MARK: - Parse from JSON
extension Note {
    
    typealias JSON = [String: Any]
    
    static func parse(json: JSON) -> Note? {
        
        guard let uuid = json["uuid"] as? String,
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
        let importance = NoteImportanceLevel(rawValue: importanceInt)!
        
        // Destruction date
        var destructionDate: Date?
        if let interval = json["destruction_date"] as? Double {
            destructionDate = Date(timeIntervalSince1970: interval)
        } else {
            destructionDate = nil
        }
        
        return Note(uuid: UUID(uuidString: uuid)!, title: title, content: content, color: color, importance: importance, destructionDate: destructionDate, createdDate: createDate)
        
    }
    
    private init(
        uuid: UUID = UUID(),
        title: String, content: String, color: UIColor = .white,
        importance: NoteImportanceLevel,
        destructionDate: Date? = nil,
        createdDate: Date
        ) {
        self.uuid = uuid
        self.title = title
        self.content = content
        self.color = color
        self.importance = importance
        self.destructionDate = destructionDate
        self.createDate = createdDate
    }
    
}

// MARK: - Parse to JSON
extension Note {
    
    var json: JSON {
        var json = JSON()
        json["uuid"] = uuid.uuidString
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
