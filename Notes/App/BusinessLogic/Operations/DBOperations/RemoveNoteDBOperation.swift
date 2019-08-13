//
//  RemoveNoteDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class RemoveNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    
    init(note: Note,
         notebook: FileNotebook) {
        self.note = note
        super.init(title: "Remove note from DataBase", notebook: notebook)
    }
    
    override func main() {
        notebook.remove(with: note.uid)
        finish()
    }
    
}
