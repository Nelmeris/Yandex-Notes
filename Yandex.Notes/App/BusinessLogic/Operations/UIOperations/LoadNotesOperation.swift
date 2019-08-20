//
//  LoadNotesOperation.swift
//  Yandex.Notes
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
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    init(note: Note,
         context: NSManagedObjectContext,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.context = context
        
        loadFromDB = LoadNotesDBOperation(context: context)
        loadFromBackend = LoadNotesBackendOperation()
        
        super.init(title: "Main load notes")
    }
    
    private func mainCompletion() {
        guard let result = loadFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let dbNotes):
            guard let result = loadFromBackend.result else {
                self.result = nil
                return
            }
            switch result {
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
    
    override func main() {
        dbQueue.addOperation(loadFromDB)
        backendQueue.addOperation(loadFromBackend)
        
        let mainOperation = BlockOperation {
            self.mainCompletion()
        }
        
        mainOperation.addDependency(loadFromDB)
        mainOperation.addDependency(loadFromBackend)
        OperationQueue().addOperation(mainOperation)
    }
    
    override func cancel() {
        loadFromDB.cancel()
        loadFromBackend.cancel()
        super.cancel()
    }
    
}
