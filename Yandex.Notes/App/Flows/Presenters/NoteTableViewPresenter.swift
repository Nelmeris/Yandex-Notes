//
//  NoteTableViewPresenter.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 20/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CoreData

protocol NoteTableViewPresenterProtocol {
    init(view: NoteTableViewProtocol, context: NSManagedObjectContext, backgroundContext: NSManagedObjectContext)
    func syncNotes()
    func loadNotesFromDB()
    func removeNote(_ note: Note)
    func startSyncTimer(with timeInterval: TimeInterval?)
    func resetSyncTimer()
}

class NoteTableViewPresenter: NoteTableViewPresenterProtocol {
    
    let viewController: NoteTableViewProtocol
    var notes: [Note] = []
    let context: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    
    var timer: Timer?
    var timerTimeInterval: TimeInterval? = nil
    
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
        lastSyncOperation?.cancel()
        stopSyncTimer()
        let syncNotesOperation = SyncNotesOperation(context: backgroundContext, backendQueue: backendQueue, dbQueue: dbQueue)
        syncNotesOperation.loadFromDB.completionBlock = {
            guard let result = syncNotesOperation.loadFromDB.result else { return }
            switch result {
            case .success(let notes):
                self.removeOutdatedNotes(notes)
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
            self.startSyncTimer()
        }
        self.lastSyncOperation = syncNotesOperation
        commonQueue.addOperation(syncNotesOperation)
    }
    
    @objc func removeNoteOBJC(timer: Timer) {
        guard let note = timer.userInfo as? Note else { return }
        timers.removeValue(forKey: note.uuid)
        self.removeNote(note)
    }
    
    var timers: [UUID: Timer] = [:]
    
    func removeOutdatedNotes(_ notes: [Note]) {
        for note in notes {
            if let date = note.destructionDate {
                if timers[note.uuid] == nil {
                    let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(removeNoteOBJC(timer:)), userInfo: note, repeats: false)
                    timers[note.uuid] = timer
                    RunLoop.main.add(timer, forMode: .default)
                }
            }
        }
    }
    
    func loadNotesFromDB() {
        let loadFromDBOperation = LoadNotesDBOperation(context: backgroundContext)
        loadFromDBOperation.completionBlock = {
            guard let result = loadFromDBOperation.result else { return }
            switch result {
            case .success(let notes):
                self.removeOutdatedNotes(notes)
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
            self.removeOutdatedNotes(notes)
            let sortedNotes = self.getSortedNotes(from: notes)
            self.viewController.setNotes(sortedNotes)
        case .backendFailture(let notes, let error):
            self.removeOutdatedNotes(notes)
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
            guard let result = removeNoteOperation.result else { return }
            self.parseUIOperationResult(from: result)
        }
        commonQueue.addOperation(removeNoteOperation)
    }
    
    func stopSyncTimer() {
        timer?.invalidate()
    }
    
    func startSyncTimer(with timeInterval: TimeInterval? = nil) {
        if let timeInterval = timeInterval {
            self.timerTimeInterval = timeInterval
        }
        guard let timeInterval = self.timerTimeInterval else { return }
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(prepareSyncNotes), userInfo: nil, repeats: true)
    }
    
    func resetSyncTimer() {
        stopSyncTimer()
        startSyncTimer(with: self.timerTimeInterval)
    }
    
    @objc func prepareSyncNotes() {
        self.syncNotes()
    }
    
}
