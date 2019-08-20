//
//  RemoveNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class RemoveNoteOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private(set) var removeFromDB: RemoveNoteDBOperation
    private(set) var loadFromDB: LoadNotesDBOperation
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    private var notes: [Note]?
    
    init(note: Note,
         context: NSManagedObjectContext,
         mainQueue: OperationQueue,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.context = context
        
        removeFromDB = RemoveNoteDBOperation(note: note, context: context)
        loadFromDB = LoadNotesDBOperation(context: context)
        
        super.init(title: "Main remove note")
    }
    
    private func saveToBackendCompletion() {
        guard let result = saveToBackend!.result else {
            self.result = nil
            return
        }
        switch result {
        case .success:
            self.result = .success(self.notes!)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: self.notes!, error: error)
        }
    }
    
    private func loadFromDBCompletion() {
        guard let result = self.loadFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            self.notes = notes
            self.saveToBackend = SaveNotesBackendOperation(notes: notes)
            let saveToBackendCompletion = BlockOperation {
                self.saveToBackendCompletion()
            }
            saveToBackendCompletion.addDependency(self.saveToBackend!)
            backendQueue.addOperation(self.saveToBackend!)
            OperationQueue().addOperation(saveToBackendCompletion)
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    private func removeFromDBCompletion() {
        switch self.removeFromDB.result! {
        case .success:
            let loadFromDBCompletion = BlockOperation {
                self.loadFromDBCompletion()
            }
            loadFromDBCompletion.addDependency(self.loadFromDB)
            dbQueue.addOperation(self.loadFromDB)
            OperationQueue().addOperation(loadFromDBCompletion)
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    override func main() {
        let removeFromDBCompletion = BlockOperation {
            self.removeFromDBCompletion()
        }
        
        removeFromDBCompletion.addDependency(removeFromDB)
        dbQueue.addOperation(removeFromDB)
        OperationQueue().addOperation(removeFromDBCompletion)
    }
    
    override func cancel() {
        removeFromDB.cancel()
        loadFromDB.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
