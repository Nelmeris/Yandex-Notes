//
//  NoteCoreDataService.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 18/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class NoteCoreDataService {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    let entityName = "CDNote"
    
    private func loadFromCD(with uuid: UUID? = nil) throws -> [CDNote] {
        let request: NSFetchRequest<CDNote> = NSFetchRequest(entityName: "CDNote")
        if let uuid = uuid {
            request.predicate = NSPredicate(format: "uuid = %@", uuid.uuidString)
        }
        return try context.fetch(request)
    }
    
    func load(with uuid: UUID? = nil) throws -> [Note] {
        let cdNotes = try loadFromCD(with: uuid)
        var notes: [Note] = []
        for cdNote in cdNotes {
            let note = Note(from: cdNote)
            notes.append(note)
        }
        return notes
    }
    
    private func saveContext(completion: @escaping (Error?) -> ()) {
        self.context.performAndWait {
            do {
                try self.context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private func save(_ note: Note) {
        let cdNote = CDNote(context: self.context)
        note.parse(toCDContainer: cdNote)
    }
    
    private func remove(_ note: CDNote) {
        self.context.delete(note)
    }
    
    private func remove(_ note: Note) throws {
        guard let cdNote = try self.loadFromCD(with: note.uuid).first else {
            print("Note not found")
            return
        }
        self.context.delete(cdNote)
    }
    
    private func removeAll() throws {
        let cdNotes = try self.loadFromCD()
        cdNotes.forEach { self.context.delete($0) }
    }
    
    private func rewrite(_ cdNote: CDNote, from note: Note) {
        cdNote.title = note.title
        cdNote.content = note.content
        cdNote.createDate = note.createDate
        cdNote.color = note.color.toHexString()
        cdNote.importance = Int16(note.importance.rawValue)
        cdNote.destructionDate = note.destructionDate
    }
    
    private func update(_ note: Note) throws {
        guard let cdNote = try self.loadFromCD(with: note.uuid).first else {
            self.save(note)
            return
        }
        self.rewrite(cdNote, from: note)
    }
    
}
    
extension NoteCoreDataService {
    
    func save(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            self.save(note)
            self.saveContext { completion($0) }
        }
    }
    
    func save(_ notes: [Note], queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            notes.forEach { self.save($0) }
            self.saveContext { completion($0) }
        }
    }
    
    func remove(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            do {
                try self.remove(note)
                self.saveContext { completion($0) }
            } catch {
                completion(error)
            }
        }
    }
    
    func removeAll(queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            do {
                try self.removeAll()
                self.saveContext { completion($0) }
            } catch {
                completion(error)
            }
        }
    }
    
    func rewrite(for notes: [Note], queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                let dbNotes = try self.loadFromCD()
                let removedNotes = dbNotes.compactMap { dbNote in
                    notes.contains { dbNote.uuid == $0.uuid.uuidString } ? nil : dbNote
                }
                removedNotes.forEach { self.remove($0) }
                
                try notes.forEach { try self.update($0) }
                self.saveContext { completion($0) }
            } catch {
                completion(error)
            }
        }
    }
    
    func update(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                try self.update(note)
                self.saveContext { completion($0) }
            } catch {
                completion(error)
            }
        }
    }
    
    func update(_ notes: [Note], queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                try notes.forEach { try self.update($0) }
                self.saveContext { completion($0) }
            } catch {
                completion(error)
            }
        }
    }
    
}
