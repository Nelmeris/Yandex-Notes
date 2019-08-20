//
//  UpdateNoteOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class UpdateNoteOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    
    private(set) var updateNoteInDB: UpdateNoteDBOperation
    private(set) var loadFromDB: LoadNotesDBOperation
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: UIOperationResult? { didSet { finish() } }
    
    init(note: Note,
         context: NSManagedObjectContext,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.context = context
        
        updateNoteInDB = UpdateNoteDBOperation(note: note, context: context)
        loadFromDB = LoadNotesDBOperation(context: self.context)
        
        super.init(title: "Main update note")
    }
    
    private func mainCompletion(_ notes: [Note]) {
        guard let result = saveToBackend!.result else {
            self.result = nil
            return
        }
        switch result {
        case .success:
            self.result = .success(notes)
        case .failure(let error):
            self.result = .backendFailture(dbNotes: notes, error: error)
        }
    }
    
    private func loadFromDBCompletion() {
        guard let result = loadFromDB.result else {
            self.result = nil
            return
        }
        switch result {
        case .success(let notes):
            self.saveToBackend = SaveNotesBackendOperation(notes: notes)
            let saveToBackendCompletion = BlockOperation {
                self.mainCompletion(notes)
            }
            saveToBackendCompletion.addDependency(self.saveToBackend!)
            backendQueue.addOperation(self.saveToBackend!)
            
            OperationQueue().addOperation(saveToBackendCompletion)
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
    private func updateNoteInDBCompletion() {
        let loadFromDBCompletion = BlockOperation {
            self.loadFromDBCompletion()
        }
        loadFromDBCompletion.addDependency(loadFromDB)
        dbQueue.addOperation(loadFromDB)
        
        OperationQueue().addOperation(loadFromDBCompletion)
    }
    
    override func main() {
        let updateNoteInDBCompletion = BlockOperation {
            self.updateNoteInDBCompletion()
        }
        updateNoteInDBCompletion.addDependency(updateNoteInDB)
        dbQueue.addOperation(updateNoteInDB)
        
        OperationQueue().addOperation(updateNoteInDBCompletion)
    }
    
    override func cancel() {
        updateNoteInDB.cancel()
        loadFromDB.cancel()
        saveToBackend?.cancel()
        super.cancel()
    }
    
}
