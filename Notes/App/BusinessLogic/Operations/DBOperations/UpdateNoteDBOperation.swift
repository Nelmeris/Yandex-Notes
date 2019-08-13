//
//  UpdateNoteDBOperation.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

class UpdateNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    
    init(note: Note,
         notebook: FileNotebook) {
        self.note = note
        super.init(title: "Update note in DataBase", notebook: notebook)
    }
    
    override func main() {
        notebook.update(note)
        finish()
    }
    
}
