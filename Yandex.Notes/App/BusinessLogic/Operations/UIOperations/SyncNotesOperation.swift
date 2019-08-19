//
//  SyncNotesOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class SyncNotesOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    
    private(set) var loadFromBackend: LoadNotesBackendOperation
    private(set) var loadFromDB: LoadNotesDBOperation
    private(set) var rewriteNotes: RewriteDBOperation?
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var syncNotes: [Note]?
    
    private let mainQueue: OperationQueue
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var result: UIOperationResult? {
        didSet {
            finish()
        }
    }
    
    func startSync() {
        switch loadFromDB.result! {
        case .success(let notes):
            switch loadFromBackend.result! {
            case .success(let container):
                let syncNotes = Note.syncNotes(dbNotes: notes, gistContainer: container)
                if syncNotes != notes {
                    rewriteNotes = RewriteDBOperation(notes: syncNotes, context: context)
                    dbQueue.addOperation(rewriteNotes!)
                    addDependency(rewriteNotes!)
                }
                if syncNotes != container.notes {
                    saveToBackend = SaveNotesBackendOperation(notes: syncNotes)
                    backendQueue.addOperation(saveToBackend!)
                    addDependency(saveToBackend!)
                }
                self.syncNotes = syncNotes
            case .failure(let error):
                self.result = .backendFailture(dbNotes: notes, error: error)
            }
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    init(
        context: NSManagedObjectContext,
        mainQueue: OperationQueue,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.context = context
        
        loadFromBackend = LoadNotesBackendOperation()
        loadFromDB = LoadNotesDBOperation(context: context)
        
        self.mainQueue = mainQueue
        self.backendQueue = backendQueue
        self.dbQueue = dbQueue
        
        super.init(title: "Sync notes with Backend")
        
        let didLoaded = BlockOperation {
            self.startSync()
        }
        
        didLoaded.addDependency(loadFromBackend)
        didLoaded.addDependency(loadFromDB)
        
        addDependency(didLoaded)
        
        backendQueue.addOperation(loadFromBackend)
        dbQueue.addOperation(loadFromDB)
        mainQueue.addOperation(didLoaded)
    }
    
    override func main() {
        if let saveOp = saveToBackend {
            switch saveOp.result! {
            case .success:
                self.result = .success(self.syncNotes!)
            case .failure(let error):
                self.result = .backendFailture(dbNotes: self.syncNotes!, error: error)
            }
        } else {
            self.result = .success(self.syncNotes!)
        }
    }
    
}
