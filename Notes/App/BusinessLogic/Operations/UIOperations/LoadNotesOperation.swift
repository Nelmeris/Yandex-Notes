//
//  LoadNotesOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class LoadNotesOperation: AsyncOperation {
    private let notebook: FileNotebook
    private let loadFromDb: LoadNotesDBOperation
    private let loadFromBackend: LoadNotesBackendOperation
    
    private(set) var result: [Note]? = nil
    
    init(notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.notebook = notebook
        
        loadFromBackend = LoadNotesBackendOperation()
        loadFromDb = LoadNotesDBOperation(notebook: notebook)
        
        super.init()
        
        addDependency(loadFromBackend)
        addDependency(loadFromDb)
        
        backendQueue.addOperation(loadFromBackend)
        dbQueue.addOperation(loadFromDb)
    }
    
    private func updateLocalData(with notes: [Note]) {
        let dbNotes = loadFromDb.result!
        var flag = false
        let maxIndex = dbNotes.count > notes.count ? notes.count : dbNotes.count
        for index in 0..<maxIndex {
            if notes[index] != dbNotes[index] {
                flag = true
                break
            }
        }
        if notes.count != dbNotes.count || flag {
            notebook.removeAll()
            notebook.add(notes)
        }
    }
    
    override func main() {
        switch loadFromBackend.result! {
        case .success(let notes):
            updateLocalData(with: notes)
            result = notes
        case .failure:
            result = loadFromDb.result!
        }
        finish()
    }
}
