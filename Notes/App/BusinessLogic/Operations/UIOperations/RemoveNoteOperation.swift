//
//  RemoveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum RemoveNoteOperationResult {
    case success
    case failture(GistServiceError)
}

class RemoveNoteOperation: AsyncOperation {
    
    private let notebook: FileNotebook
    private(set) var removeFromDB: RemoveNoteDBOperation
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: RemoveNoteOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.notebook = notebook
        
        removeFromDB = RemoveNoteDBOperation(note: note, notebook: notebook)
        
        super.init(title: "Main remove note")
        
        let fakeOp = BlockOperation {
            let saveToBackend = SaveNotesBackendOperation(notes: notebook.notes)
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            backendQueue.addOperation(saveToBackend)
        }
        
        addDependency(removeFromDB)
        addDependency(fakeOp)
        fakeOp.addDependency(removeFromDB)
        
        dbQueue.addOperation(removeFromDB)
        dbQueue.addOperation(fakeOp)
    }
    
    override func main() {
        switch saveToBackend!.result! {
        case .success:
            result = .success
        case .failure(let error):
            result = .failture(error)
        }
    }
    
}
