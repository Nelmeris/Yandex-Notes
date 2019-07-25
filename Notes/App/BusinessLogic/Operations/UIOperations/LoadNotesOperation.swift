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
        
        addDependency(loadFromDb)
        addDependency(loadFromBackend)
        
        dbQueue.addOperation(loadFromDb)
        backendQueue.addOperation(loadFromBackend)
    }
    
    private func updateLocalData(with notes: [Note]) {
        let dbNotes = loadFromDb.result!
        var flag = false
        for index in 0..<dbNotes.count {
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
