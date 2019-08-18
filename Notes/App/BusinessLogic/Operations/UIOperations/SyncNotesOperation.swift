//
//  SyncNotesOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SyncNotesOperationResult {
    case success([Note])
    case failture(GistServiceError)
}

class SyncNotesOperation: AsyncOperation {
    
    private let notebook: FileNotebook
    
    private(set) var loadFromBackend: LoadNotesBackendOperation
    private(set) var loadFromDB: LoadNotesDBOperation
    private(set) var rewriteNotes: RewriteNotesOperation?
    
    private(set) var syncNotes: [Note]?
    
    private let mainQueue: OperationQueue
    private let dbQueue: OperationQueue
    private let backendQueue: OperationQueue
    
    private(set) var result: SyncNotesOperationResult? {
        didSet {
            finish()
        }
    }
    
    private func isOutdated(dbNote: Note, backendNote: Note) -> Bool {
        return dbNote != backendNote &&
            dbNote.createDate > backendNote.createDate
    }
    
    private func isDeleted(note: Note, gistContainer: GistNotesContainer) -> Bool {
        return note.createDate > gistContainer.lastUpdateDate
    }
    
    private func syncNotes(dbNotes: [Note], gistContainer: GistNotesContainer) -> [Note] {
        var newNotes = gistContainer.notes
        for dbNote in dbNotes {
            if let noteInGist = newNotes.first(where: { $0.uid == dbNote.uid }) {
                if isOutdated(dbNote: dbNote, backendNote: noteInGist) {
                    newNotes.removeAll { $0.uid == dbNote.uid }
                    newNotes.append(dbNote)
                }
            } else {
                if isDeleted(note: dbNote, gistContainer: gistContainer) {
                    newNotes.append(dbNote)
                }
            }
        }
        
        return newNotes
    }
    
    func startSync() {
        switch loadFromBackend.result! {
        case .success(let container):
            let syncNotes = self.syncNotes(dbNotes: loadFromDB.result!, gistContainer: container)
            self.rewriteNotes = RewriteNotesOperation(notes: syncNotes, notebook: notebook, backendQueue: backendQueue, dbQueue: dbQueue)
            mainQueue.addOperation(rewriteNotes!)
            addDependency(rewriteNotes!)
            self.syncNotes = syncNotes
        case .failure(let error):
            self.result = .failture(error)
        }
    }
    
    init(
        notebook: FileNotebook,
        mainQueue: OperationQueue,
        backendQueue: OperationQueue,
        dbQueue: OperationQueue
        ) {
        self.notebook = notebook
        
        loadFromBackend = LoadNotesBackendOperation()
        loadFromDB = LoadNotesDBOperation(notebook: notebook)
        
        self.mainQueue = mainQueue
        self.backendQueue = backendQueue
        self.dbQueue = dbQueue
        
        super.init(title: "Sync notes with Backend")
        
        let didLoaded = BlockOperation {
            self.startSync()
        }
        
        didLoaded.addDependency(loadFromBackend)
        didLoaded.addDependency(loadFromDB)
        
        addDependency(loadFromBackend)
        addDependency(loadFromDB)
        addDependency(didLoaded)
        
        backendQueue.addOperation(loadFromBackend)
        dbQueue.addOperation(loadFromDB)
        mainQueue.addOperation(didLoaded)
    }
    
    override func main() {
        switch self.rewriteNotes!.result! {
        case .success:
            self.result = .success(self.syncNotes!)
        case .failture(let error):
            self.result = .failture(error)
        }
    }
    
}
