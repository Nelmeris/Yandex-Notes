//
//  Note.swift
//  Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

struct Note: Equatable {
    
    enum ImportanceLevels: Int {
        case insignificant, usual, critical
    }
    
    let uid: String
    
    let title: String
    let content: String
    let color: UIColor
    let importance: ImportanceLevels
    
    let destructionDate: Date?
    let createDate: Date
    
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
        self.destructionDate = selfDestructionDate
        self.createDate = Date()
    }
    
    static func ==(lhs: Note, rhs: Note) -> Bool {
        return lhs.uid == rhs.uid &&
            lhs.title == rhs.title &&
            lhs.content == rhs.content &&
            lhs.color == rhs.color &&
            lhs.importance == rhs.importance &&
            lhs.destructionDate == rhs.destructionDate
    }
    
}
