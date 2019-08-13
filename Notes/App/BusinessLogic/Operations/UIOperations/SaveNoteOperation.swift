//
//  SaveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class SaveNoteOperation: AsyncOperation {
    
    private let note: Note
    private let notebook: FileNotebook
    
    private(set) var saveToDb: SaveNoteDBOperation
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: Bool? = false {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.note = note
        self.notebook = notebook
        
        saveToDb = SaveNoteDBOperation(note: note, notebook: notebook)
        
        super.init(title: "Main save note")
        
        // Дополнительная зависимость, чтобы успеть добавить зависимость saveToBackend
        let fakeOp = BlockOperation {
            let saveToBackend = SaveNotesBackendOperation(notes: notebook.notes)
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            backendQueue.addOperation(saveToBackend)
        }
        
        addDependency(saveToDb)
        addDependency(fakeOp)
        fakeOp.addDependency(saveToDb)
        
        dbQueue.addOperation(saveToDb)
        dbQueue.addOperation(fakeOp)
    }
    
    override func main() {
        switch saveToBackend!.result! {
        case .success:
            self.result = true
        case .failure(let error):
            self.result = false
            print(error.localizedDescription)
        }
    }
    
}
