//
//  NoteCoreDataService.swift
//  Notes
//
//  Created by Артем Куфаев on 18/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation
import CoreData

class NoteCoreDataService {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    let entityName = "CDNote"
    
    private func loadFromCD(with uid: String? = nil) throws -> [CDNote] {
        let request: NSFetchRequest<CDNote> = NSFetchRequest(entityName: "CDNote")
        if let uid = uid {
            request.predicate = NSPredicate(format: "uid = %@", uid)
        }
        return try context.fetch(request)
    }
    
    func load(with uid: String? = nil) throws -> [Note] {
        let cdNotes = try loadFromCD(with: uid)
        var notes: [Note] = []
        for cdNote in cdNotes {
            let note = Note(from: cdNote)
            notes.append(note)
        }
        return notes
    }
    
    func save(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            let cdNote = CDNote(context: self.context)
            _ = note.parse(toCDContainer: cdNote)
            self.context.performAndWait {
                do {
                    try self.context.save()
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    func save(_ notes: [Note], queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            for note in notes {
                let cdNote = CDNote(context: self.context)
                _ = note.parse(toCDContainer: cdNote)
            }
            self.context.performAndWait {
                do {
                    try self.context.save()
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    func remove(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            do {
                guard let cdNote = try self.loadFromCD(with: note.uid).first else { fatalError("Note not found") }
                self.context.performAndWait {
                    self.context.delete(cdNote)
                    do {
                        try self.context.save()
                        completion(nil)
                    } catch {
                        completion(error)
                    }
                }
            } catch {
                completion(error)
            }
        }
    }
    
    private func rewrite(_ cdNote: CDNote, from note: Note) -> CDNote {
        cdNote.title = note.title
        cdNote.content = note.content
        cdNote.createDate = note.createDate
        cdNote.color = note.color.toHexString()
        cdNote.importance = Int16(note.importance.rawValue)
        cdNote.destructionDate = note.destructionDate
        return cdNote
    }
    
    func update(_ note: Note, queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                guard var cdNote = try self.loadFromCD(with: note.uid).first else { fatalError("Note not found") }
                
                cdNote = self.rewrite(cdNote, from: note)
                
                do {
                    try self.context.save()
                    completion(nil)
                } catch {
                    completion(error)
                }
            } catch {
                completion(error)
            }
        }
    }
    
    func removeAll(queue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        queue.async {
            do {
                let cdNotes = try self.loadFromCD()
                self.context.performAndWait {
                    for cdNote in cdNotes {
                        self.context.delete(cdNote)
                    }
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        }
    }
    
}
