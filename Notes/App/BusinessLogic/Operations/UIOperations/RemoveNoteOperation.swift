//
//  RemoveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class RemoveNoteOperation: AsyncOperation {
    private let notebook: FileNotebook
    private let removeFromDB: RemoveNoteDBOperation
    private var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: Bool?
    
    init(note: Note,
         notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.notebook = notebook
        
        removeFromDB = RemoveNoteDBOperation(note: note, notebook: notebook)
        
        super.init()
        
        // Дополнительная зависимость, чтобы успеть добавить зависимость saveToBackend
        let fakeOp = Operation()
        addDependency(fakeOp)
        
        removeFromDB.completionBlock = {
            let saveToBackend = SaveNotesBackendOperation(notes: notebook.notes)
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            self.removeDependency(fakeOp)
            backendQueue.addOperation(saveToBackend)
        }
        
        addDependency(removeFromDB)
        dbQueue.addOperation(removeFromDB)
    }
    
    override func main() {
        switch saveToBackend!.result! {
        case .success:
            result = true
        case .failure:
            result = false
        }
        
        finish()
    }
}
