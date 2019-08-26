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
    func createNote(withData data: NoteData, completion: @escaping ([Note]?) -> ())
    func editNote(_ note: Note, withData data: NoteData, completion: @escaping ([Note]?) -> ())
}

class EditNotePresenter: EditNotePresenterProtocol {
    
    let viewController: EditNoteViewProtocol
    let backgroundContext: NSManagedObjectContext
    
    let uiQueue = BaseUIOperation.queue
    let backendQueue = BaseBackendOperation.queue
    let dbQueue = BaseDBOperation.queue
    
    required init(view: EditNoteViewProtocol, backgroundContext: NSManagedObjectContext) {
        self.viewController = view
        self.backgroundContext = backgroundContext
    }
    
    func changeColor() {
        viewController.goToColorPicker()
    }
    
    func createNote(withData data: NoteData, completion: @escaping ([Note]?) -> ()) {
        let newNote = Note(from: data)
        let saveNoteOperation = SaveNoteOperation(note: newNote, context: backgroundContext, backendQueue: backendQueue, dbQueue: BaseDBOperation.queue)
        
        saveNoteOperation.loadFromDB.completionBlock = {
            guard let result = saveNoteOperation.loadFromDB.result else { return }
            switch result {
            case .success(let notes):
                completion(notes)
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        
        uiQueue.addOperation(saveNoteOperation)
    }
    
    func editNote(_ note: Note, withData data: NoteData, completion: @escaping ([Note]?) -> ()) {
        let newNote = Note(from: data, withUUID: note.uuid)
        guard !(note == newNote) else { return }
        
        let updateNoteOperation = UpdateNoteOperation(note: newNote, context: backgroundContext, backendQueue: backendQueue, dbQueue: dbQueue)
        
        updateNoteOperation.loadFromDB.completionBlock = {
            guard let result = updateNoteOperation.loadFromDB.result else { return }
            switch result {
            case .success(let notes):
                completion(notes)
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
        
        uiQueue.addOperation(updateNoteOperation)
    }
    
}
