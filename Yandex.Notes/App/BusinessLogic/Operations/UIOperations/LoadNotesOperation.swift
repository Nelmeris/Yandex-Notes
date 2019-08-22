//
//  LoadNotesOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class LoadNotesOperation: BaseUIOperation {
    
    private let context: NSManagedObjectContext
    
    private(set) var loadFromDB: LoadNotesDBOperation!
    private(set) var loadFromBackend: LoadNotesBackendOperation!
    private(set) var rewriteDB: RewriteDBOperation?
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    private var notesFromDB: [Note]?
    private var notesFromBackend: [Note]?
    
    private var syncNotes: [Note]?
    
    init(context: NSManagedObjectContext,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue,
         id: Int? = nil,
         title: String? = nil
        ) {
        self.context = context
        self.dbQueue = dbQueue
        self.backendQueue = backendQueue
        
        let id = AsyncOperationID(number: id, title: title ?? "Main load notes")
        super.init(id: id)
        
        loadFromDB = LoadNotesDBOperation(context: context, id: self.id?.number)
        loadFromBackend = LoadNotesBackendOperation(id: self.id?.number)
        
        guard !self.isCancelled else { return }
        dbQueue.addOperation(loadFromDB)
        loadFromBackend.addDependency(loadFromDB)
        guard !self.isCancelled else { return }
        backendQueue.addOperation(loadFromBackend)
        
        let loadFromDBCompletionBlock = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletionBlock.addDependency(loadFromDB)
        guard !self.isCancelled else { return }
        AsyncOperation.commonQueue.addOperation(loadFromDBCompletionBlock)
        
        let loadFromBackendCompletionBlock = BlockOperation {
            self.loadFromBackendCompletion()
        }
        loadFromBackendCompletionBlock.addDependency(loadFromBackend)
        guard !self.isCancelled else { return }
        AsyncOperation.commonQueue.addOperation(loadFromBackendCompletionBlock)
        
        
        self.addDependency(loadFromBackendCompletionBlock)
        
        self.addDependency(loadFromDB)
        self.addDependency(loadFromBackend)
    }
    
    private func startRewriteDB() {
        guard let notes = self.syncNotes else { fatalError() }
        let rewriteDB = RewriteDBOperation(notes: notes, context: context, id: id?.number)
        self.rewriteDB = rewriteDB
        guard !self.isCancelled else { return }
        dbQueue.addOperation(rewriteDB)
        addDependency(rewriteDB)
    }
    
    private func startSaveToBackend() {
        guard let notes = self.syncNotes else { fatalError() }
        let saveToBackend = SaveNotesBackendOperation(notes: notes, id: id?.number)
        self.saveToBackend = saveToBackend
        guard !self.isCancelled else { return }
        backendQueue.addOperation(saveToBackend)
        addDependency(saveToBackend)
    }
    
    private func loadFromBackendCompletion() {
        guard let result = loadFromBackend.result else {
            self.result = nil
            return
        }
        guard let dbNotes = self.notesFromDB else { fatalError() }
        switch result {
        case .success(let gistContainer):
            let resultSync = Note.syncNotes(dbNotes: dbNotes, gistContainer: gistContainer)
            self.syncNotes = resultSync.notes
            switch resultSync.type {
            case .dbNeedsUpdate:
                self.startRewriteDB()
            case .backendNeedsUpdate:
                self.startSaveToBackend()
            case .needsBilateralUpdate:
                self.startRewriteDB()
                self.startSaveToBackend()
            default: break
            }
        case .failure(let error):
            self.result = .backendFailture(dbNotes: dbNotes, error: error)
        }
    }
    
    private func loadFromDBCompletion() {
        guard let result = loadFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            self.notesFromDB = notes
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    private func rewriteDBCompletion() {
        guard let result = rewriteDB?.result else {
            self.result = nil
            return
        }
        switch result {
        case .failture(let error):
            self.result = .dbFailture(error)
        default: break
        }
    }
    
    private func saveToBackendCompletion() {
        guard let result = saveToBackend?.result else {
            self.result = nil
            return
        }
        guard let syncNotes = syncNotes else { fatalError() }
        switch result {
        case .failure(let error):
            self.result = .backendFailture(dbNotes: syncNotes, error: error)
        default: break
        }
    }
    
    override func main() {
        if rewriteDB != nil {
            rewriteDBCompletion()
        }
        if saveToBackend != nil {
            saveToBackendCompletion()
        }
        guard let syncNotes = syncNotes else { fatalError() }
        guard self.result == nil else { return }
        self.result = .success(syncNotes)
    }
    
    override func cancel() {
        loadFromDB.cancel()
        loadFromBackend.cancel()
        rewriteDB?.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
