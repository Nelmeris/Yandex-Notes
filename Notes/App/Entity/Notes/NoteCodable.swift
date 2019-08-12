//
//  NoteCodable.swift
//  Notes
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

extension Note: Codable {
    
    enum CodingKeys: String, CodingKey {
        case uid, title, content, color, importance
        case destructionDate = "destruction_date"
        case createDate = "create_date"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        color = UIColor(hexString: try container.decode(String.self, forKey: .color))
        importance = try container.decode(ImportanceLevels.self, forKey: .importance)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        destructionDate = dateFormatter.date(from: (try? container.decode(String.self, forKey: .destructionDate)) ?? "")
        createDate = dateFormatter.date(from: try container.decode(String.self, forKey: .createDate))!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uid, forKey: .uid)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(color.toHexString(), forKey: .color)
        try container.encode(importance, forKey: .importance)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let destructionDate = destructionDate {
            try container.encode(dateFormatter.string(from: destructionDate), forKey: .destructionDate)
        }
        try container.encode(dateFormatter.string(from: createDate), forKey: .createDate)
    }
    
}
