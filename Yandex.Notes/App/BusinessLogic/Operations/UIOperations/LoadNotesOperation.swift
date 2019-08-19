//
//  LoadNotesOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class LoadNotesOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private(set) var loadFromDB: LoadNotesDBOperation
    private(set) var loadFromBackend: LoadNotesBackendOperation
    
    private(set) var result: UIOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         context: NSManagedObjectContext,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.context = context
        
        loadFromDB = LoadNotesDBOperation(context: context)
        loadFromBackend = LoadNotesBackendOperation()
        
        super.init(title: "Main load notes")
        
        dbQueue.addOperation(loadFromDB)
        backendQueue.addOperation(loadFromBackend)
        
        addDependency(loadFromDB)
        addDependency(loadFromBackend)
    }
    
    override func main() {
        switch loadFromDB.result! {
        case .success(let dbNotes):
            switch loadFromBackend.result! {
            case .success(let gistContainer):
                let newNotes = Note.syncNotes(dbNotes: dbNotes, gistContainer: gistContainer)
                self.result = .success(newNotes)
            case .failure(let error):
                self.result = .backendFailture(dbNotes: dbNotes, error: error)
            }
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
}
