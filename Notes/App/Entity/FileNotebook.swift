//
//  FileNotebook.swift
//  Notes
//
//  Created by Артем Куфаев on 02/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

class FileNotebook {
    
    private(set) var notes: [Note] = []
    private(set) var isAutosave: Bool = false
    
    public func setAutosave(_ value: Bool) {
        isAutosave = value
    }
    
    public func contain(with uid: String) -> Bool {
        return notes.contains { $0.uid == uid }
    }
    
    public func add(_ note: Note) {
        guard !contain(with: note.uid) else { return }
        notes.append(note)
        if isAutosave {
            saveToFile()
        }
    }
    
    public func remove(with uid: String) {
        notes.removeAll { $0.uid == uid }
        if isAutosave {
            saveToFile()
        }
    }
    
    public func get(with uid: String) -> Note? {
        return notes.first { $0.uid == uid }
    }
    
    public func update(_ note: Note) {
        guard contain(with: note.uid) else { return }
        remove(with: note.uid)
        add(note)
    }
    
    public func saveToFile() {
        let json = notes.map { $0.json }
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        guard let fileURL = FileNotebook.getFilePath() else { return }
        do {
            try data.write(to: fileURL)
        } catch let error {
            print(error)
        }
    }
    
    public func loadFromFile() {
        guard let fileURL = FileNotebook.getFilePath() else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonArray = try!
                JSONSerialization.jsonObject(with: data, options: [])
                as! [[String: Any]]
            self.notes = jsonArray.compactMap { Note.parse(json: $0) }
        } catch let error {
            print(error)
        }
    }
    
    static public func removeFile() {
        guard let fileURL = getFilePath() else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch let error {
            print(error)
        }
    }
    
    static func getFilePath() -> URL? {
        if let dir = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask).first {
            let file = "notebook.json"
            let fileURL = dir.appendingPathComponent(file)
            return fileURL
        } else { return nil }
    }
    
    static func isFileCreated() -> Bool {
        guard let pathComponent = FileNotebook.getFilePath() else { return false }
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    init() {
        if !FileNotebook.isFileCreated() {
            saveToFile()
            print("Notebook was created")
        }
    }
    
}
