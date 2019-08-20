//
//  Note.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

struct Note: Equatable {
    
    let uuid: UUID
    
    let title: String
    let content: String
    let color: UIColor
    let importance: NoteImportanceLevel
    
    let destructionDate: Date?
    
    let createDate: Date
    
    init(
        uuid: UUID = UUID(),
        title: String, content: String, color: UIColor = .white,
        importance: NoteImportanceLevel,
        destructionDate: Date? = nil
        ) {
        self.uuid = uuid
        self.title = title
        self.content = content
        self.color = color
        self.importance = importance
        self.destructionDate = destructionDate
        self.createDate = Date()
    }
    
    init(from data: NoteData, withUUID uuid: UUID = UUID()) {
        self.init(uuid: uuid, title: data.title, content: data.content, color: data.color, importance: data.importance, destructionDate: data.destructionDate)
    }
    
    static func ==(lhs: Note, rhs: Note) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.title == rhs.title &&
            lhs.content == rhs.content &&
            lhs.color.toHexString() == rhs.color.toHexString() &&
            lhs.importance == rhs.importance &&
            lhs.destructionDate == rhs.destructionDate
    }
    
}

