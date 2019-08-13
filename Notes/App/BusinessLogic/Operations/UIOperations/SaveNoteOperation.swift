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
    private let saveToDb: SaveNoteDBOperation
    private var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: Bool? = false
    
    init(note: Note,
         notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.note = note
        self.notebook = notebook
        
        saveToDb = SaveNoteDBOperation(note: note, notebook: notebook)
        
        super.init()
        
        addDependency(saveToDb)
        
        // Дополнительная зависимость, чтобы успеть добавить зависимость saveToBackend
        let fakeOp = Operation()
        addDependency(fakeOp)
        
        saveToDb.completionBlock = {
            print("Save to DataBase operation completed")
            let saveToBackend = SaveNotesBackendOperation(notes: notebook.notes)
            saveToBackend.completionBlock = {
                print("Save to Backend operation completed")
            }
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            self.removeDependency(fakeOp)
            backendQueue.addOperation(saveToBackend)
        }
        
        dbQueue.addOperation(saveToDb)
    }
    
    override func main() {
        print("Start save operation")
        switch saveToBackend!.result! {
        case .success:
            self.result = true
        case .failure(let error):
            self.result = false
            print(error.localizedDescription)
        }
        self.finish()
    }
}
