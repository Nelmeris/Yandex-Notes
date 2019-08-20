//
//  NoteTableViewPresenter.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 20/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit
import CoreData

protocol NoteTableViewPresenterProtocol {
    init(view: NoteTableViewProtocol, context: NSManagedObjectContext, backgroundContext: NSManagedObjectContext)
    func syncNotes()
    func loadNotesFromDB()
    func removeNote(_ note: Note)
}

class NoteTableViewPresenter: NoteTableViewPresenterProtocol {
    
    let viewController: NoteTableViewProtocol
    var notes: [Note] = []
    let context: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    
    func getSortCompare() -> (Note, Note) -> Bool {
        return { lft, rht in
            return lft.createDate > rht.createDate
        }
    }
    
    private func getSortedNotes(from notes: [Note]) -> [Note] {
        return notes.sorted(by: getSortCompare())
    }
    
    required init(view: NoteTableViewProtocol, context: NSManagedObjectContext, backgroundContext: NSManagedObjectContext) {
        self.viewController = view
        self.context = context
        self.backgroundContext = backgroundContext
    }
    
    var lastSyncOperation: SyncNotesOperation? = nil
    
    func syncNotes() {
        lastSyncOperation?.finish()
        viewController.beginRefreshing()
        let syncNotesOperation = SyncNotesOperation(context: backgroundContext, mainQueue: commonQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        syncNotesOperation.loadFromDB.completionBlock = {
            switch syncNotesOperation.loadFromDB.result! {
            case .success(let notes):
                let sortedNotes = self.getSortedNotes(from: notes)
                self.viewController.setNotes(sortedNotes)
            case .failture(let error):
                fatalError(error.localizedDescription)
            }
        }
        syncNotesOperation.completionBlock = {
            guard let result = syncNotesOperation.result else { return }
            self.viewController.endRefreshing()
            self.parseUIOperationResult(from: result)
        }
        self.lastSyncOperation = syncNotesOperation
        commonQueue.addOperation(syncNotesOperation)
    }
    
    func loadNotesFromDB() {
        let loadFromDBOperation = LoadNotesDBOperation(context: backgroundContext)
        loadFromDBOperation.completionBlock = {
            switch loadFromDBOperation.result! {
            case .success(let notes):
                let sortedNotes = self.getSortedNotes(from: notes)
                self.viewController.setNotes(sortedNotes)
            case .failture(let error):
                print(error.localizedDescription)
            }
        }
        dbQueue.addOperation(loadFromDBOperation)
    }
    
    let noConnectionTimerKey = "no_connection_timer"
    func noConnectionHandler() {
        let userDefaults = UserDefaults.standard
        let time = userDefaults.double(forKey: noConnectionTimerKey)
        userDefaults.value(forKey: noConnectionTimerKey)
        if time == 0 || Date().timeIntervalSince1970 - time > 300 {
            viewController.alert(with: "Внимание!", message: "Отсутствует подключение к сети")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: noConnectionTimerKey)
        }
    }
    
    func parseUIOperationResult(from result: UIOperationResult) {
        switch result {
        case .success(let notes):
            let sortedNotes = self.getSortedNotes(from: notes)
            self.viewController.setNotes(sortedNotes)
        case .backendFailture(let notes, let error):
            let sortedNotes = self.getSortedNotes(from: notes)
            self.viewController.setNotes(sortedNotes)
            switch error {
            case .failed(let netError):
                switch netError {
                case .failedRequest(let requestError):
                    switch requestError {
                    case .noConnection:
                        noConnectionHandler()
                    default:
                        print(requestError.localizedDescription)
                    }
                case .failedResponse(let responseError):
                    print(responseError.localizedDescription)
                }
            default:
                print(error.localizedDescription)
            }
        case .dbFailture(let error):
            fatalError(error.localizedDescription)
        }
    }
    
    func removeNote(_ note: Note) {
        let removeNoteOperation = RemoveNoteOperation(note: note, context: backgroundContext, mainQueue: commonQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        removeNoteOperation.removeFromDB.completionBlock = {
            self.loadNotesFromDB()
        }
        removeNoteOperation.completionBlock = {
            self.parseUIOperationResult(from: removeNoteOperation.result!)
        }
        commonQueue.addOperation(removeNoteOperation)
    }
    
}
