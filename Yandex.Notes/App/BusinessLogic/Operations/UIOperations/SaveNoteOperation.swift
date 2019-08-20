//
//  SaveNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class SaveNoteOperation: AsyncOperation {
    
    private let note: Note
    private let context: NSManagedObjectContext
    
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    private let syncQueue: OperationQueue
    
    private(set) var saveToDb: SaveNoteDBOperation
    private(set) var syncNotes: SyncNotesOperation
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    init(
        note: Note,
        context: NSManagedObjectContext,
        syncQueue: OperationQueue,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.note = note
        self.context = context
        self.dbQueue = dbQueue
        self.backendQueue = backendQueue
        self.syncQueue = syncQueue
        
        saveToDb = SaveNoteDBOperation(note: note, context: context)
        syncNotes = SyncNotesOperation(context: context, backendQueue: backendQueue, dbQueue: dbQueue)
        
        super.init(title: "Main save note")
    }
    
    private func syncNotesCompletion() {
        guard let result = syncNotes.result else {
            self.result = nil
            return
        }
        self.result = result
    }
    
    private func saveToDBCompletion() {
        guard let result = saveToDb.result else {
            self.result = nil
            return
        }
        switch result {
        case .success:
            self.syncNotesCompletion()
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    override func main() {
        dbQueue.addOperation(saveToDb)
        syncQueue.addOperation(syncNotes)
        
        syncNotes.addDependency(saveToDb)
        
        let saveToDbCompletion = BlockOperation {
            self.saveToDBCompletion()
        }
        
        OperationQueue().addOperation(saveToDbCompletion)
    }
    
    override func cancel() {
        saveToDb.cancel()
        syncNotes.cancel()
        super.cancel()
    }
    
}
