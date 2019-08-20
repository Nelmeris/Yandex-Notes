//
//  NoteCoreDataParsing.swift
//  Notes
//
//  Created by Artem Kufaev on 18/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

// MARK: - Parse from CoreData
extension Note {
    
    init(from cdNote: CDNote) {
        self.uid = UUID(uuidString: cdNote.uid!)!
        self.title = cdNote.title!
        self.content = cdNote.content!
        self.color = UIColor(hexString: cdNote.color!)
        self.createDate = cdNote.createDate!
        self.destructionDate = cdNote.destructionDate
        self.importance = NoteImportanceLevel(rawValue: Int(cdNote.importance))!
    }
    
}

// MARK: - Parse to CoreData
extension Note {
    
    func parse(toCDContainer cdNote: CDNote) -> CDNote {
        cdNote.uid = self.uid.uuidString
        cdNote.title = self.title
        cdNote.content = self.content
        cdNote.color = self.color.toHexString()
        cdNote.createDate = self.createDate
        cdNote.destructionDate = self.destructionDate
        cdNote.importance = Int16(self.importance.rawValue)
        return cdNote
    }
    
}
