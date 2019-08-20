//
//  SyncNotesOperation.swift
//  Yandex.Notes
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
    
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    init(
        context: NSManagedObjectContext,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.context = context
        
        loadFromBackend = LoadNotesBackendOperation()
        loadFromDB = LoadNotesDBOperation(context: context)
        
        self.backendQueue = backendQueue
        self.dbQueue = dbQueue
        
        super.init(title: "Sync notes with Backend")
    }
    
    private func mainCompletion() {
        guard let saveOp = saveToBackend else {
            self.result = .success(self.syncNotes!)
            return
        }
        guard let result = saveOp.result else {
            self.result = nil
            return
        }
        switch result {
        case .success:
            self.result = .success(self.syncNotes!)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: self.syncNotes!, error: error)
        }
    }
    
    private func startSync() {
        guard let result = loadFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            guard let result = loadFromBackend.result else {
                self.result = nil
                return
            }
            switch result {
            case .success(let container):
                let syncNotes = Note.syncNotes(dbNotes: notes, gistContainer: container)
                
                let mainCompletion = BlockOperation {
                    self.mainCompletion()
                }
                
                if syncNotes != notes {
                    rewriteNotes = RewriteDBOperation(notes: syncNotes, context: context)
                    dbQueue.addOperation(rewriteNotes!)
                    mainCompletion.addDependency(rewriteNotes!)
                }
                if syncNotes != container.notes {
                    saveToBackend = SaveNotesBackendOperation(notes: syncNotes)
                    backendQueue.addOperation(saveToBackend!)
                    mainCompletion.addDependency(saveToBackend!)
                }
                self.syncNotes = syncNotes
                
                OperationQueue().addOperation(mainCompletion)
            case .failure(let error):
                self.result = .backendFailture(dbNotes: notes, error: error)
            }
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    override func main() {
        let didLoaded = BlockOperation {
            self.startSync()
        }
        
        didLoaded.addDependency(loadFromBackend)
        didLoaded.addDependency(loadFromDB)
        
        backendQueue.addOperation(loadFromBackend)
        dbQueue.addOperation(loadFromDB)
        
        OperationQueue().addOperation(didLoaded)
    }
    
    override func cancel() {
        loadFromDB.cancel()
        loadFromBackend.cancel()
        rewriteNotes?.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
