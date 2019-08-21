//
//  EditNotePresenter.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 20/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

protocol EditNotePresenterProtocol {
    init(view: EditNoteViewProtocol, backgroundContext: NSManagedObjectContext)
    func changeColor()
    func createNote(withData data: NoteData, completion: @escaping () -> ())
    func editNote(_ note: Note, withData data: NoteData, completion: @escaping () -> ())
}

class EditNotePresenter: EditNotePresenterProtocol {
    
    let viewController: EditNoteViewProtocol
    let backgroundContext: NSManagedObjectContext
    
    required init(view: EditNoteViewProtocol, backgroundContext: NSManagedObjectContext) {
        self.viewController = view
        self.backgroundContext = backgroundContext
    }
    
    func changeColor() {
        viewController.goToColorPicker()
    }
    
    func createNote(withData data: NoteData, completion: @escaping () -> ()) {
        let newNote = Note(from: data)
        let saveNoteOperation = SaveNoteOperation(note: newNote, context: backgroundContext, backendQueue: backendQueue, dbQueue: BaseDBOperation.queue)
        
        saveNoteOperation.saveToDB?.completionBlock = {
            completion()
        }
        
        BaseUIOperation.queue.addOperation(saveNoteOperation)
    }
    
    func editNote(_ note: Note, withData data: NoteData, completion: @escaping () -> ()) {
        let newNote = Note(from: data, withUUID: note.uuid)
        guard !(note == newNote) else { return }
        
        let updateNoteOperation = UpdateNoteOperation(note: newNote, context: backgroundContext, backendQueue: backendQueue, dbQueue: BaseDBOperation.queue)
        
        updateNoteOperation.updateInDB?.completionBlock = {
            completion()
        }
        
        BaseUIOperation.queue.addOperation(updateNoteOperation)
    }
    
}
