//
//  RemoveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class RemoveNoteOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private(set) var removeFromDB: RemoveNoteDBOperation
    private(set) var loadFromDB: LoadNotesDBOperation?
    private(set) var saveToBackend: SaveNotesBackendOperation?
    
    private(set) var result: UIOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         context: NSManagedObjectContext,
         mainQueue: OperationQueue,
         backendQueue: OperationQueue,
         dbQueue: OperationQueue) {
        self.context = context
        
        removeFromDB = RemoveNoteDBOperation(note: note, context: context)
        
        super.init(title: "Main remove note")
        
        let removeFromDBCompletion = BlockOperation {
            self.loadFromDB = LoadNotesDBOperation(context: context)
            
            let loadFromDBCompletion = BlockOperation {
                switch self.loadFromDB!.result! {
                case .success(let notes):
                    self.saveToBackend = SaveNotesBackendOperation(notes: notes)
                    backendQueue.addOperation(self.saveToBackend!)
                    self.addDependency(self.saveToBackend!)
                case .failture(let error):
                    self.result = .dbFailture(error)
                }
            }
            loadFromDBCompletion.addDependency(self.loadFromDB!)
            
            dbQueue.addOperation(self.loadFromDB!)
            dbQueue.addOperation(loadFromDBCompletion)
            
            self.addDependency(loadFromDBCompletion)
        }
        
        removeFromDBCompletion.addDependency(removeFromDB)
        
        dbQueue.addOperation(removeFromDB)
        dbQueue.addOperation(removeFromDBCompletion)
        
        addDependency(removeFromDBCompletion)
    }
    
    override func main() {
        switch loadFromDB!.result! {
        case .success(let notes):
            switch saveToBackend!.result! {
            case .success:
                self.result = .success(notes)
            case .failure(let error):
                self.result = .backendFailture(dbNotes: notes, error: error)
            }
        case .failture(let error):
            self.result = .dbFailture(error)
        }
    }
    
}
