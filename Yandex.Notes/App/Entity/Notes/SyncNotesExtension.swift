//
//  ExistNotesSelection.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

extension Note {
    
    static fileprivate func isOutdated(dbNote: Note, backendNote: Note) -> Bool {
        return dbNote != backendNote &&
            dbNote.createDate > backendNote.createDate
    }
    
    static fileprivate func isDeleted(note: Note, gistContainer: GistNotesContainer) -> Bool {
        return note.createDate > gistContainer.lastUpdateDate
    }
    
    static func syncNotes(dbNotes: [Note], gistContainer: GistNotesContainer) -> [Note] {
        var newNotes = gistContainer.notes
        for dbNote in dbNotes {
            if let noteInGist = newNotes.first(where: { $0.uuid == dbNote.uuid }) {
                if isOutdated(dbNote: dbNote, backendNote: noteInGist) {
                    newNotes.removeAll { $0.uuid == dbNote.uuid }
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
    
}
