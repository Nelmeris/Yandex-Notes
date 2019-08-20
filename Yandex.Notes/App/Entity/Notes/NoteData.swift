//
//  NoteData.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 20/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

struct NoteData: Equatable {
    
    let title: String
    let content: String
    let color: UIColor
    let importance: NoteImportanceLevel
    
    let destructionDate: Date?
    
    init(
        title: String, content: String, color: UIColor = .white,
        importance: NoteImportanceLevel,
        destructionDate: Date? = nil
        ) {
        self.title = title
        self.content = content
        self.color = color
        self.importance = importance
        self.destructionDate = destructionDate
    }
    
    static func ==(lhs: NoteData, rhs: NoteData) -> Bool {
        return
            lhs.title == rhs.title &&
            lhs.content == rhs.content &&
            lhs.color.toHexString() == rhs.color.toHexString() &&
            lhs.importance == rhs.importance &&
            lhs.destructionDate == rhs.destructionDate
    }
    
}

