//
//  Note.swift
//  Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

struct Note: Equatable {
    
    let uid: UUID
    
    let title: String
    let content: String
    let color: UIColor
    let importance: NoteImportanceLevel
    
    let destructionDate: Date?
    
    let createDate: Date
    
    init(
        uid: UUID = UUID(),
        title: String, content: String, color: UIColor = .white,
        importance: NoteImportanceLevel,
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
    
    init(from data: NoteData, withUUID uuid: UUID = UUID()) {
        self.init(uid: uuid, title: data.title, content: data.content, color: data.color, importance: data.importance, destructionDate: data.destructionDate)
    }
    
    static func ==(lhs: Note, rhs: Note) -> Bool {
        return lhs.uid == rhs.uid &&
            lhs.title == rhs.title &&
            lhs.content == rhs.content &&
            lhs.color.toHexString() == rhs.color.toHexString() &&
            lhs.importance == rhs.importance &&
            lhs.destructionDate == rhs.destructionDate
    }
    
}

