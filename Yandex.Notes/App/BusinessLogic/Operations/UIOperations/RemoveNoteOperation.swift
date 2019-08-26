//
//  RemoveNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class RemoveNoteOperation: BaseUIOperation {
    
    private let context: NSManagedObjectContext
    
    private(set) var removeFromDB: RemoveNoteDBOperation!
    private(set) var loadFromDB: LoadNotesDBOperation!
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    private var notes: [Note]?
    
    init(note: Note,
         context: NSManagedObjectContext,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue,
         id: Int? = nil,
         title: String? = nil
        ) {
        self.context = context
        self.backendQueue = backendQueue
        self.dbQueue = dbQueue
        
        let id = AsyncOperationID(number: id, title: title ?? "Main remove note")
        super.init(id: id)
        
        removeFromDB = RemoveNoteDBOperation(note: note, context: context, id: self.id?.number)
        loadFromDB = LoadNotesDBOperation(context: context, id: self.id?.number)
        
        guard !self.isCancelled else { return }
        dbQueue.addOperation(removeFromDB)
        loadFromDB.addDependency(removeFromDB)
        guard !self.isCancelled else { return }
        dbQueue.addOperation(loadFromDB)
        
        let removeFromDBCompletionBlock = BlockOperation {
            self.removeFromDBCompletion()
        }
        removeFromDBCompletionBlock.addDependency(removeFromDB)
        guard !self.isCancelled else { return }
        commonQueue.addOperation(removeFromDBCompletionBlock)
        
        let loadFromDBCompletionBlock = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletionBlock.addDependency(loadFromDB)
        guard !self.isCancelled else { return }
        commonQueue.addOperation(loadFromDBCompletionBlock)
        
        self.addDependency(loadFromDBCompletionBlock)
    }
    
    private func removeFromDBCompletion() {
        guard let result = removeFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .failure(let error):
            self.result = .dbFailure(error)
        default: break
        }
    }
    
    private func loadFromDBCompletion() {
        guard let result = self.loadFromDB!.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            self.notes = notes
            let saveToBackend = SaveNotesBackendOperation(notes: notes, id: self.id?.number)
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            guard !self.isCancelled else { return }
            backendQueue.addOperation(saveToBackend)
        case .failure(let error):
            self.result = .dbFailure(error)
        }
    }
    
    override func main() {
        guard let result = saveToBackend!.result else {
            self.result = nil
            return
        }
        switch result {
        case .success:
            self.result = .success(self.notes!)
        case .failure:
            self.result = .backendFailure(dbNotes: self.notes!, error: nil)
        case .failureRequest(let error):
            self.result = .backendFailure(dbNotes: self.notes!, error: error)
        }
    }
    
    override func cancel() {
        super.cancel()
        saveToBackend?.cancel()
        removeFromDB?.cancel()
        loadFromDB?.cancel()
    }
    
}
