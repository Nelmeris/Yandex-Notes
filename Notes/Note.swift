//
//  Note.swift
//  Notes
//
//  Created by Артем Куфаев on 02/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

struct Note {
    
    enum ImportanceLevels {
        case unimportant, ordinary, important
    }
    
    let uid: String
    
    let title: String
    let content: String
    let color: UIColor
    let importance: ImportanceLevels
    
    let selfDestructionDate: Date?
    
    init(
        uid: String = UUID().uuidString,
        title: String, content: String, color: UIColor = .white,
        importance: ImportanceLevels,
        destructionDate selfDestructionDate: Date? = nil
        ) {
        self.uid = uid
        self.title = title
        self.content = content
        self.color = color
        self.importance = importance
        self.selfDestructionDate = selfDestructionDate
    }
    
}
