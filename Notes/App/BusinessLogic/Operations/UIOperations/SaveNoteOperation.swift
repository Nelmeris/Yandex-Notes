//
//  SaveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SaveNoteOperationResult {
    case success
    case failture(GistServiceError)
}

class SaveNoteOperation: AsyncOperation {
    
    private let note: Note
    private let notebook: FileNotebook
    
    private(set) var saveToDb: SaveNoteDBOperation
    private(set) var syncNotes: SyncNotesOperation?
    
    private(set) var result: SaveNoteOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(
        note: Note,
        notebook: FileNotebook,
        mainQueue: OperationQueue,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.note = note
        self.notebook = notebook
        
        saveToDb = SaveNoteDBOperation(note: note, notebook: notebook)
        
        super.init(title: "Main save note")
        
        // Дополнительная зависимость, чтобы успеть добавить зависимость saveToBackend
        let fakeOp = BlockOperation {
            let syncNotes = SyncNotesOperation(notebook: notebook, mainQueue: mainQueue, backendQueue: backendQueue, dbQueue: dbQueue)
            self.syncNotes = syncNotes
            self.addDependency(syncNotes)
            mainQueue.addOperation(syncNotes)
        }
        
        addDependency(saveToDb)
        addDependency(fakeOp)
        fakeOp.addDependency(saveToDb)
        
        dbQueue.addOperation(saveToDb)
        dbQueue.addOperation(fakeOp)
    }
    
    override func main() {
        switch syncNotes!.result! {
        case .success:
            self.result = .success
        case .failture(let error):
            self.result = .failture(error)
        }
    }
    
}
