//
//  SaveNoteOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class SaveNoteOperation: AsyncOperation {
    
    private let note: Note
    private let context: NSManagedObjectContext
    
    private(set) var saveToDb: SaveNoteDBOperation
    private(set) var syncNotes: SyncNotesOperation
    
    private(set) var result: UIOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(
        note: Note,
        context: NSManagedObjectContext,
        mainQueue: OperationQueue,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.note = note
        self.context = context
        
        saveToDb = SaveNoteDBOperation(note: note, context: context)
        syncNotes = SyncNotesOperation(context: context, mainQueue: mainQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        
        super.init(title: "Main save note")
        
        dbQueue.addOperation(saveToDb)
        mainQueue.addOperation(syncNotes)
        
        syncNotes.addDependency(saveToDb)
        addDependency(syncNotes)
    }
    
    override func main() {
        self.result = syncNotes.result!
    }
    
}
