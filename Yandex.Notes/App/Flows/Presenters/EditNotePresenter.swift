//
//  EditNotePresenter.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 20/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation
import CoreData

protocol EditNotePresenterProtocol {
    init(view: EditNoteViewProtocol, backgroundContext: NSManagedObjectContext)
    func changeColor()
    func createNote(withData data: NoteData)
    func editNote(_ note: Note, withData data: NoteData)
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
    
    func createNote(withData data: NoteData) {
        let newNote = Note(from: data)
        let saveNoteOperation = SaveNoteOperation(note: newNote, context: backgroundContext, mainQueue: commonQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        
        saveNoteOperation.saveToDb.completionBlock = {
            self.viewController.loadNotesFromDBOnDestination()
        }
        
        commonQueue.addOperation(saveNoteOperation)
    }
    
    func editNote(_ note: Note, withData data: NoteData) {
        let newNote = Note(from: data, withUUID: note.uid)
        guard !(note == newNote) else { return }
        
        let updateNoteOperation = UpdateNoteOperation(note: newNote, context: backgroundContext, backendQueue: backendQueue, dbQueue: dbQueue)
        
        updateNoteOperation.updateNoteInDB.completionBlock = {
            self.viewController.loadNotesFromDBOnDestination()
        }
        
        commonQueue.addOperation(updateNoteOperation)
    }
    
}
