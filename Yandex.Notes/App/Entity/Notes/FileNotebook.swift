//
//  FileNotebook.swift
//  Notes
//
//  Created by Artem Kufaev on 02/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class FileNotebook {
    
    private(set) var notes: [Note] = []
    private(set) var isAutosave: Bool = true
    
    static private let fileName = "notebook.json"
    
    static public let shared = FileNotebook()
    
    private init() {
        guard FileNotebook.isFileCreated() else {
            saveToFile()
            print("Notebook was created")
            return
        }
        loadFromFile()
    }
    
    public func setAutosave(_ value: Bool) {
        isAutosave = value
    }
    
    public func contain(with uid: UUID) -> Bool {
        return notes.contains { $0.uid == uid }
    }
    
    public func add(_ note: Note) {
        guard !contain(with: note.uid) else { return }
        notes.append(note)
        if isAutosave {
            saveToFile()
        }
    }
    
    public func add(_ notes: [Note]) {
        for note in notes {
            add(note)
        }
    }
    
    public func remove(with uid: UUID) {
        notes.removeAll { $0.uid == uid }
        if isAutosave {
            saveToFile()
        }
    }
    
    public func removeAll() {
        notes.removeAll()
        if isAutosave {
            saveToFile()
        }
    }
    
    public func get(with uid: UUID) -> Note? {
        return notes.first { $0.uid == uid }
    }
    
    public func update(_ note: Note) {
        guard contain(with: note.uid) else { return }
        remove(with: note.uid)
        add(note)
    }
    
}

// MARK: - Work with file
extension FileNotebook {
    
    static func getFilePath() -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            return fileURL
        } else { return nil }
    }
    
    static func isFileCreated() -> Bool {
        guard let pathComponent = FileNotebook.getFilePath() else { return false }
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    public func saveToFile() {
        let notes = self.notes
        let json = notes.map { $0.json }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let fileURL = FileNotebook.getFilePath() else { return }
            try data.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func loadFromFile() {
        guard let fileURL = FileNotebook.getFilePath() else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonArray = try
                JSONSerialization.jsonObject(with: data, options: [])
                as! [[String: Any]]
            self.notes = jsonArray.compactMap { Note.parse(json: $0) }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static public func removeFile() {
        guard let fileURL = getFilePath() else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
