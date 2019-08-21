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
    
    func loadNotes()
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
    
    var syncTimer: Timer?
    var syncTimerTimeInterval: TimeInterval? = nil
    
    var removeTimers: [UUID: Timer] = [:]
    
    var currentLoadOperation: LoadNotesOperation?
    
    let noConnectionTimerKey = "no_connection_timer"
    
    func getSortCompare() -> (Note, Note) -> Bool {
        return { $0.createDate > $1.createDate }
    }
    
    private func getSortedNotes(from notes: [Note]) -> [Note] {
        return notes.sorted(by: getSortCompare())
    }
    
    required init(view: NoteTableViewProtocol, context: NSManagedObjectContext, backgroundContext: NSManagedObjectContext) {
        self.viewController = view
        self.context = context
        self.backgroundContext = backgroundContext
    }
    
    func removeOutdatedNotes(_ notes: [Note]) {
        for note in notes {
            guard let date = note.destructionDate,
                removeTimers[note.uuid] == nil else { continue }
            let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
                self.removeTimers.removeValue(forKey: note.uuid)
                self.removeNote(note)
            }
            removeTimers[note.uuid] = timer
            RunLoop.main.add(timer, forMode: .default)
        }
    }
    
    private func setNotes(_ notes: [Note]) {
        if let currentLoadOperation = self.currentLoadOperation,
            !currentLoadOperation.isFinished {
            self.currentLoadOperation?.cancel()
        }
        self.currentLoadOperation = nil
        self.resetSyncTimer()
        self.removeOutdatedNotes(notes)
        let sortedNotes = self.getSortedNotes(from: notes)
        self.viewController.setNotes(sortedNotes)
    }
    
}

extension NoteTableViewPresenter {
    
    func loadNotes() {
        if self.currentLoadOperation != nil { return }
        let nsLock = NSLock()
        nsLock.lock()
        stopSyncTimer()
        let loadNotesOperation = LoadNotesOperation(context: backgroundContext, backendQueue: BaseBackendOperation.queue, dbQueue: BaseDBOperation.queue)
        self.currentLoadOperation = loadNotesOperation
        nsLock.unlock()
        loadNotesOperation.loadFromDB?.completionBlock = {
            guard let result = loadNotesOperation.loadFromDB?.result else { return }
            switch result {
            case .failture(let error):
                fatalError(error.localizedDescription)
            default:
                break
            }
        }
        loadNotesOperation.completionBlock = {
            self.viewController.endRefreshing()
            guard let result = loadNotesOperation.result else { return }
            switch result {
            case .success(let notes):
                self.setNotes(notes)
            default:
                break
            }
            self.parseUIOperationResult(from: result)
        }
        BaseUIOperation.queue.addOperation(loadNotesOperation)
    }
    
    func loadNotesFromDB() {
        let loadFromDBOperation = LoadNotesDBOperation(context: backgroundContext)
        loadFromDBOperation.completionBlock = {
            guard let result = loadFromDBOperation.result else { return }
            switch result {
            case .success(let notes):
                self.setNotes(notes)
            case .failture(let error):
                print(error.localizedDescription)
            }
        }
        BaseDBOperation.queue.addOperation(loadFromDBOperation)
    }
   
    func removeNote(_ note: Note) {
        let removeNoteOperation = RemoveNoteOperation(note: note, context: backgroundContext, backendQueue: BaseBackendOperation.queue, dbQueue: BaseDBOperation.queue)
        removeNoteOperation.loadFromDB?.completionBlock = {
            switch removeNoteOperation.loadFromDB!.result! {
            case .success(let notes):
                self.setNotes(notes)
            case .failture(let error):
                print(error.localizedDescription)
            }
        }
        removeNoteOperation.completionBlock = {
            guard let result = removeNoteOperation.result else { return }
            self.parseUIOperationResult(from: result)
        }
        BaseUIOperation.queue.addOperation(removeNoteOperation)
    }
    
}

extension NoteTableViewPresenter {
    
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
        case .backendFailture(_, let error):
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
        default: break
        }
    }
    
}

// MARK: - Sync timer
extension NoteTableViewPresenter {
    
    func startSyncTimer(with timeInterval: TimeInterval? = nil) {
        if let timeInterval = timeInterval {
            self.syncTimerTimeInterval = timeInterval
        }
        guard let timeInterval = self.syncTimerTimeInterval else { return }
        syncTimer = Timer(fire: Date().addingTimeInterval(timeInterval), interval: 0, repeats: false) { _ in
            self.loadNotes()
        }
        RunLoop.main.add(syncTimer!, forMode: .common)
    }
    
    func stopSyncTimer() {
        syncTimer?.invalidate()
    }
    
    func resetSyncTimer() {
        stopSyncTimer()
        startSyncTimer()
    }
    
}
