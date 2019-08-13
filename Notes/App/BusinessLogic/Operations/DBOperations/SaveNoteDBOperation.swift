//
//  SaveNoteDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class SaveNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    
    init(note: Note,
         notebook: FileNotebook) {
        self.note = note
        super.init(title: "Save note to DataBase", notebook: notebook)
    }
    
    override func main() {
        notebook.add(note)
        finish()
    }
    
}
