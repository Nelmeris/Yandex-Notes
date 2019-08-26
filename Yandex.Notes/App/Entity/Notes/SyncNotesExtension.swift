//
//  SyncNotesExtension.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SyncNotesResultType {
    case synchronized
    case dbNeedsUpdate
    case backendNeedsUpdate
    case needsBilateralUpdate
}

struct SyncNotesResult {
    let notes: [Note]
    let type: SyncNotesResultType
}

extension Note {
    
    // Если просрочена (вторая новее)
    static fileprivate func isOutdated(note: Note, comparedNote: Note) -> Bool {
        return note != comparedNote &&
            note.createDate < comparedNote.createDate
    }
    
    // Если новая, созданная на клиенте
    static fileprivate func isNew(note: Note, gistContainer: GistNotesContainer) -> Bool {
        return note.createDate > gistContainer.lastUpdateDate
    }
    
    // Если удалена с сервера, но хранится на клиенте
    static fileprivate func isDeleted(note: Note, gistContainer: GistNotesContainer) -> Bool {
        return note.createDate < gistContainer.lastUpdateDate
    }
    
    static private func returnIfNotContains(note: Note, in array: [Note]) -> Note? {
        return array.contains { $0.uuid == note.uuid } ? nil : note
    }
    
    static private func returnIfContains(note: Note, in array: [Note]) -> Note? {
        return array.contains { $0.uuid == note.uuid } ? note : nil
    }
    
    static private func returnIfContainsAndNotEqual(note: Note, in array: [Note]) -> Note? {
        guard let compareNote = array.first(where: { $0.uuid == note.uuid }) else { return nil }
        return note != compareNote ? note : nil
    }
    
    static private func getSimularNotes(
        fromDB dbNotes: [Note],
        fromBackend backendNotes: [Note]
        ) -> [(dbNote: Note, backendNote: Note)] {
        var simularNotes: [(dbNote: Note, backendNote: Note)] = []
        for dbNote in dbNotes {
            if let backendNote = backendNotes.first(where: { $0.uuid == dbNote.uuid }) {
                simularNotes.append((dbNote: dbNote, backendNote: backendNote))
            }
        }
        return simularNotes
    }
    
    static func getNewNotes(in newArray: [Note], compare oldArray: [Note]) -> [Note] {
        return newArray
            .compactMap { returnIfNotContains(note: $0, in: oldArray) }
    }
    
    static func getDeletedNotes(in newArray: [Note], compare oldArray: [Note]) -> [Note] {
        return oldArray
            .compactMap { returnIfNotContains(note: $0, in: newArray) }
    }
    
    static func getUpdatedNotes(in newArray: [Note], compare oldArray: [Note]) -> [Note] {
        return newArray
            .compactMap { returnIfContainsAndNotEqual(note: $0, in: oldArray) }
    }
    
    // TODO: - Если удалена на клиенте, но хранится на сервере (?)
    
    // Синхронизация заметок на клиенте и сервере
    static func sync(dbNotes: [Note], gistContainer: GistNotesContainer) -> SyncNotesResult {
        let backendNotes = gistContainer.notes
        
        // Проверка на синхронность
        guard !dbNotes.elementsEqual(backendNotes) else {
            return SyncNotesResult(notes: dbNotes, type: .synchronized)
        }
        
        var syncNotes: [Note] = []
        
        var isBackendNeedsUpdate = false
        var isDBNeedsUpdate = false
        
        // Новые заметки на сервере (отсутствующие локально)
        let newNotesOnBackend = getNewNotes(in: backendNotes, compare: dbNotes)
        // Новые заметки на устройстве (отсутствующие на сервере)
        let newNotesOnDB = getNewNotes(in: dbNotes, compare: backendNotes)
        // Схожие заметки (с одним и тем же UUID)
        let similarNotes = getSimularNotes(fromDB: dbNotes, fromBackend: backendNotes)
        
        
        for note in newNotesOnDB {
            // Если новая
            if isNew(note: note, gistContainer: gistContainer) {
                syncNotes.append(note)
                isBackendNeedsUpdate = true
            }
            // TODO: - Если удалена с сервера (а если она новая и просто сервер был обновлен позже ее создания? (время обновления сервера позже времени создания заметки))
            if isDeleted(note: note, gistContainer: gistContainer) {
                isDBNeedsUpdate = true
            }
        }
        
        // TODO: - Невозможно проверить, была ли заметка удалена локально или просто создана на другом устройстве
        // (можно проверить по id устройства?)
        for note in newNotesOnBackend {
            syncNotes.append(note)
            isDBNeedsUpdate = true
        }
        
        // Проверка похожих заметок
        for (dbNote, backendNote) in similarNotes {
            guard dbNote != backendNote else { // Если не отличаются
                syncNotes.append(dbNote)
                continue
            }
            if isOutdated(note: dbNote, comparedNote: backendNote) { // Если серверная новее
                syncNotes.append(backendNote)
                isDBNeedsUpdate = true
            } else if isOutdated(note: backendNote, comparedNote: dbNote) { // Если локальная новее
                syncNotes.append(dbNote)
                isBackendNeedsUpdate = true
            }
        }
        
        if isDBNeedsUpdate && isBackendNeedsUpdate {
            return SyncNotesResult(notes: syncNotes, type: .needsBilateralUpdate)
        } else if isDBNeedsUpdate {
            return SyncNotesResult(notes: syncNotes, type: .dbNeedsUpdate)
        } else {
            return SyncNotesResult(notes: syncNotes, type: .backendNeedsUpdate)
        }
        
    }
    
}
