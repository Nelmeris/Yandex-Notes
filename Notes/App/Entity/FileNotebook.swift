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
    
    public func contain(with uid: String) -> Bool {
        for note in notes {
            if note.uid == uid {
                return true
            }
        }
        return false
    }
    
    public func add(_ note: Note) {
        guard !contain(with: note.uid) else { return }
        notes.append(note)
    }
    
    public func remove(with uid: String) {
        notes.removeAll { note -> Bool in
            note.uid == uid
        }
    }
    
    public func get(with uid: String) -> Note? {
        return notes.drop { note -> Bool in
            return note.uid == uid
        }.first
    }
    
    public func update(_ note: Note) {
        guard contain(with: note.uid) else { return }
        remove(with: note.uid)
        add(note)
    }
    
    public func saveToFile() {
        var json: [[String: Any]] = []
        for note in notes {
            json.append(note.json)
        }
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
            var notes = [Note]()
            let data = try Data(contentsOf: fileURL)
            let jsonArray = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
            for jsonObject in jsonArray {
                if let note = Note.parse(json: jsonObject) {
                    notes.append(note)
                }
            }
            self.notes = notes
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
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let file = "notebook.json"
            let fileURL = dir.appendingPathComponent(file)
            return fileURL
        } else { return nil }
    }
    
    init() {
        guard let pathComponent = FileNotebook.getFilePath() else { return }
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            loadFromFile()
            print("Notebook was loaded")
        } else {
            saveToFile()
            print("Notebook was created")
        }
    }
    
}
