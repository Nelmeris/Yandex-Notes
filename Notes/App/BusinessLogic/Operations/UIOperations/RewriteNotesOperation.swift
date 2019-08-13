//
//  RewriteNotesOperation.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum RewriteNotesOperationResult {
    case success
    case failture(GistServiceError)
}

class RewriteNotesOperation: AsyncOperation {
    
    private let notes: [Note]
    private let notebook: FileNotebook
    
    private(set) var rewriteInDb: RewriteDBOperation
    private(set) var saveToBackend: SaveNotesBackendOperation
    
    private(set) var result: RewriteNotesOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(notes: [Note],
         notebook: FileNotebook,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.notes = notes
        self.notebook = notebook
        
        rewriteInDb = RewriteDBOperation(notes: notes, notebook: notebook)
        saveToBackend = SaveNotesBackendOperation(notes: notes)
        
        super.init(title: "Main rewrite notes")
        
        addDependency(rewriteInDb)
        addDependency(saveToBackend)
        
        dbQueue.addOperation(rewriteInDb)
        backendQueue.addOperation(saveToBackend)
    }
    
    override func main() {
        switch saveToBackend.result! {
        case .success:
            self.result = .success
        case .failure(let error):
            self.result = .failture(error)
        }
    }
    
}
