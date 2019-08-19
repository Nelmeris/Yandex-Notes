//
//  NoteCoreDataParsing.swift
//  Notes
//
//  Created by Артем Куфаев on 18/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

// MARK: - Parse from CoreData
extension Note {
    
    init(from cdNote: CDNote) {
        self.uid = cdNote.uid!
        self.title = cdNote.title!
        self.content = cdNote.content!
        self.color = UIColor(hexString: cdNote.color!)
        self.createDate = cdNote.createDate!
        self.destructionDate = cdNote.destructionDate
        self.importance = ImportanceLevels(rawValue: Int(cdNote.importance))!
    }
    
}

// MARK: - Parse to CoreData
extension Note {
    
    func parse(toCDContainer cdNote: CDNote) -> CDNote {
        cdNote.uid = self.uid
        cdNote.title = self.title
        cdNote.content = self.content
        cdNote.color = self.color.toHexString()
        cdNote.createDate = self.createDate
        cdNote.destructionDate = self.destructionDate
        cdNote.importance = Int16(self.importance.rawValue)
        return cdNote
    }
    
}
