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
        
        dbQueue.addOperation(loadFromDB)
        loadFromBackend.addDependency(loadFromDB)
        backendQueue.addOperation(loadFromBackend)
        
        let loadFromDBCompletionBlock = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletionBlock.addDependency(loadFromDB)
        AsyncOperation.commonQueue.addOperation(loadFromDBCompletionBlock)
        
        let loadFromBackendCompletionBlock = BlockOperation {
            self.loadFromBackendCompletion()
        }
        loadFromBackendCompletionBlock.addDependency(loadFromBackend)
        AsyncOperation.commonQueue.addOperation(loadFromBackendCompletionBlock)
        
        
        self.addDependency(loadFromBackendCompletionBlock)
        
        self.addDependency(loadFromDB)
        self.addDependency(loadFromBackend)
    }
    
    private func startRewriteDB(with notes: [Note]) {
        let rewriteDB = RewriteDBOperation(notes: notes, context: context, id: id?.number)
        self.rewriteDB = rewriteDB
        dbQueue.addOperation(rewriteDB)
        addDependency(rewriteDB)
    }
    
    private func startSaveToBackend(with notes: [Note]) {
        let saveToBackend = SaveNotesBackendOperation(notes: notes, id: id?.number)
        self.saveToBackend = saveToBackend
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
            switch resultSync {
            case .synchronized:
                self.result = .success(dbNotes)
            case .dbNeedsUpdate(let notes):
                self.syncNotes = notes
                self.startRewriteDB(with: notes)
            case .backendNeedsUpdate(let notes):
                self.syncNotes = notes
                self.startSaveToBackend(with: notes)
            case .needsBilateralUpdate(let notes):
                self.syncNotes = notes
                self.startRewriteDB(with: notes)
                self.startSaveToBackend(with: notes)
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
        guard let syncNotes = syncNotes else { fatalError() }
        switch result {
        case .success:
            self.result = .success(syncNotes)
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    private func saveToBackendCompletion() {
        guard let result = saveToBackend?.result else {
            self.result = nil
            return
        }
        guard let syncNotes = syncNotes else { fatalError() }
        switch result {
        case .success:
            self.result = .success(syncNotes)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: syncNotes, error: error)
        }
    }
    
    override func main() {
        if rewriteDB != nil {
            rewriteDBCompletion()
        }
        if saveToBackend != nil {
            saveToBackendCompletion()
        }
    }
    
    override func cancel() {
        loadFromDB.cancel()
        loadFromBackend.cancel()
        rewriteDB?.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
