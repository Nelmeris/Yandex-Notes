//
//  SaveNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class SaveNoteOperation: BaseUIOperation {
    
    private let note: Note
    private let context: NSManagedObjectContext
    
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var saveToDB: SaveNoteDBOperation!
    private(set) var loadFromDB: LoadNotesDBOperation!
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    private var notes: [Note]?
    
    init(
        note: Note,
        context: NSManagedObjectContext,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue,
        id: Int? = nil,
        title: String? = nil
        ) {
        self.note = note
        self.context = context
        self.dbQueue = dbQueue
        self.backendQueue = backendQueue
        
        let id = AsyncOperationID(number: id, title: title ?? "Main save note")
        super.init(id: id)
        
        saveToDB = SaveNoteDBOperation(note: note, context: context, id: self.id?.number)
        loadFromDB = LoadNotesDBOperation(context: context, id: self.id?.number)
        
        guard !self.isCancelled else { return }
        dbQueue.addOperation(saveToDB)
        loadFromDB.addDependency(saveToDB)
        guard !self.isCancelled else { return }
        dbQueue.addOperation(loadFromDB)
        
        let saveToDBCompletionBlock = BlockOperation {
            self.saveToDBCompletion()
        }
        saveToDBCompletionBlock.addDependency(saveToDB)
        guard !self.isCancelled else { return }
        AsyncOperation.commonQueue.addOperation(saveToDBCompletionBlock)
        
        let loadFromDBCompletionBlock = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletionBlock.addDependency(loadFromDB)
        guard !self.isCancelled else { return }
        AsyncOperation.commonQueue.addOperation(loadFromDBCompletionBlock)
        
        self.addDependency(loadFromDBCompletionBlock)
    }
    
    private func saveToDBCompletion() {
        guard let result = saveToDB.result else {
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
        guard let result = loadFromDB.result else {
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
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    override func main() {
        guard let result = saveToBackend?.result else {
            self.result = nil
            return
        }
        guard let notes = self.notes else { fatalError() }
        switch result {
        case .success:
            self.result = .success(notes)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: notes, error: error)
        }
    }
    
    override func cancel() {
        saveToDB.cancel()
        loadFromDB.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
