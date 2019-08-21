//
//  UpdateNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class UpdateNoteOperation: BaseUIOperation {
    
    private let context: NSManagedObjectContext
    
    private(set) var updateInDB: UpdateNoteDBOperation!
    private(set) var loadFromDB: LoadNotesDBOperation!
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private let backendQueue: OperationQueue
    private let dbQueue: OperationQueue
    
    private var notes: [Note]?
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
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
        
        let id = AsyncOperationID(number: id, title: title ?? "Main update note")
        super.init(id: id)
        
        updateInDB = UpdateNoteDBOperation(note: note, context: context, id: self.id?.number)
        loadFromDB = LoadNotesDBOperation(context: self.context, id: self.id?.number)
        
        dbQueue.addOperation(updateInDB)
        loadFromDB.addDependency(updateInDB)
        dbQueue.addOperation(loadFromDB)
        
        let updateInDBCompletionBlock = BlockOperation {
            self.updateInDBCompletion()
        }
        updateInDBCompletionBlock.addDependency(updateInDB)
        AsyncOperation.commonQueue.addOperation(updateInDBCompletionBlock)
        
        let loadFromDBCompletionBlock = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletionBlock.addDependency(loadFromDB)
        AsyncOperation.commonQueue.addOperation(loadFromDBCompletionBlock)
        
        self.addDependency(loadFromDBCompletionBlock)
    }
    
    private func updateInDBCompletion() {
        guard let result = updateInDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .failture(let error):
            self.result = .dbFailture(error)
        default: break
        }
    }
    
    private func loadFromDBCompletion() {
        guard let result = loadFromDB!.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            self.notes = notes
            let saveToBackend = SaveNotesBackendOperation(notes: notes, id: self.id?.number)
            self.saveToBackend = saveToBackend
            self.addDependency(saveToBackend)
            backendQueue.addOperation(saveToBackend)
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    override func main() {
        guard let result = saveToBackend!.result else {
            self.result = nil
            return
        }
        guard let notes = notes else { fatalError() }
        switch result {
        case .success:
            self.result = .success(notes)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: notes, error: error)
        }
    }
    
    override func cancel() {
        updateInDB.cancel()
        loadFromDB.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
