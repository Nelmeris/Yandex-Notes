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
    func removeNote(_ note: Note)
    
    func startSync(with timeInterval: TimeInterval?)
    func restartSync()
}

class NoteTableViewPresenter: NoteTableViewPresenterProtocol {
    
    let viewController: NoteTableViewProtocol
    var notes: [Note] = []
    let context: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    let uiQueue = BaseUIOperation.queue
    let backendQueue = BaseBackendOperation.queue
    let dbQueue = BaseDBOperation.queue
    
    var syncTimer: Timer?
    var syncTimerTimeInterval: TimeInterval? = nil
    
    var removeTimers: [UUID: Timer] = [:]
    let dispatchGroup = DispatchGroup()
    
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
        removeOutdatedNotes(notes)
        let sortedNotes = getSortedNotes(from: notes)
        viewController.setNotes(sortedNotes)
    }
    
}

extension NoteTableViewPresenter {
    
    func loadNotes() {
        DispatchQueue.global(qos: .background).async {
            self.uiQueue.waitUntilAllOperationsAreFinished()
            self.dispatchGroup.wait()
            if self.currentLoadOperation != nil { return }
            self.dispatchGroup.enter()
            self.stopSync()
            let loadNotesOperation = LoadNotesOperation(context: self.backgroundContext, backendQueue: self.backendQueue, dbQueue: self.dbQueue)
            self.currentLoadOperation = loadNotesOperation
            self.dispatchGroup.leave()
            loadNotesOperation.loadFromDB?.completionBlock = {
                guard let result = loadNotesOperation.loadFromDB?.result else { return }
                switch result {
                case .success(let notes):
                    self.setNotes(notes)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
            loadNotesOperation.completionBlock = {
                self.viewController.endRefreshing()
                guard let result = loadNotesOperation.result else { return }
                switch result {
                case .success(let notes):
                    self.setNotes(notes)
                default: break
                }
                self.parseUIOperationResult(from: result)
                self.restartSync()
            }
            self.uiQueue.addOperation(loadNotesOperation)
        }
    }
   
    func removeNote(_ note: Note) {
        stopSync()
        let removeNoteOperation = RemoveNoteOperation(note: note, context: backgroundContext, backendQueue: BaseBackendOperation.queue, dbQueue: BaseDBOperation.queue)
        removeNoteOperation.loadFromDB?.completionBlock = {
            switch removeNoteOperation.loadFromDB!.result! {
            case .success(let notes):
                self.setNotes(notes)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        removeNoteOperation.completionBlock = {
            guard let result = removeNoteOperation.result else { return }
            self.parseUIOperationResult(from: result)
            self.restartSync()
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
        case .backendFailure(_, let error):
            guard let error = error else { return }
            switch error {
            case .noConnection:
                noConnectionHandler()
            default:
                print(error.localizedDescription)
            }
        case .dbFailure(let error):
            fatalError(error.localizedDescription)
        default: break
        }
    }
    
}

// MARK: - Sync timer
extension NoteTableViewPresenter {
    
    func startSync(with timeInterval: TimeInterval? = nil) {
        if let timeInterval = timeInterval {
            self.syncTimerTimeInterval = timeInterval
        }
        guard let timeInterval = self.syncTimerTimeInterval else { return }
        syncTimer = Timer(fire: Date().addingTimeInterval(timeInterval), interval: 0, repeats: false) { _ in
            self.loadNotes()
        }
        RunLoop.main.add(syncTimer!, forMode: .common)
    }
    
    func stopSync() {
        syncTimer?.invalidate()
        if (!(currentLoadOperation?.isFinished ?? true)) {
            currentLoadOperation?.cancel()
        }
        currentLoadOperation = nil
    }
    
    func restartSync() {
        stopSync()
        startSync()
    }
    
}
