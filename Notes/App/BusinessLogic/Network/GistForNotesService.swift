//
//  GistForNotesService.swift
//  Notes
//
//  Created by Артем Куфаев on 12/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

class GistForNotesService {
    
    private init() {}
    static let shared = GistForNotesService()
    
    private let gistName = "ios-course-notes-db"
    private let gistIdKey = "gist_for_notes_id"
    
    private var gistId: String! {
        get {
            return UserDefaults.standard.string(forKey: gistIdKey)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: gistIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: gistIdKey)
            }
        }
    }
    
    private func createGistCreator(with notes: [Note] = []) throws -> GistCreator {
        let data = try JSONEncoder().encode(notes)
        let gistContent = String(data: data, encoding: .utf8)
        let gistFileCreator = GistFileCreator(content: gistContent!)
        let gistCreator = GistCreator(public: true, description: gistName, files: [gistName: gistFileCreator])
        return gistCreator
    }
    
    private func parseNotes(from gist: Gist) throws -> [Note]? {
        guard let file = gist.files[gistName],
            let content = file.content,
            let data = content.data(using: .utf8) else { return nil }
        let notes = try JSONDecoder().decode([Note].self, from: data)
        return notes
    }
    
    private func findGist(completion: @escaping (_ result: Bool, _ error: GistServiceErrors?) -> Void) {
        GistService.shared.search(for: gistName) { (result, error) in
            // Если не найден
            guard let gist = result else {
                completion(false, error)
                return
            }
            // Если найден
            self.gistId = gist.id
            completion(true, nil)
        }
    }
    
    func isNotebookCreated(completion: @escaping (_ result: Bool, _ error: GistServiceErrors?) -> Void) {
        if gistId != nil {
            GistService.shared.get(with: gistId) { (result, error) in
                guard result != nil else {
                    self.findGist { completion($0, $1) }
                    return
                }
                completion(true, nil)
            }
        } else {
            findGist { completion($0, $1) }
        }
    }
    
    func createGist(with notes: [Note] = [], completion: @escaping (GistServiceErrors?) -> Void) {
        do {
            let gistCreator = try createGistCreator(with: notes)
            GistService.shared.create(with: gistCreator) { (result, error) in // Создать его
                if let gist = result { // Если успешно
                    self.gistId = gist.id // Сохранить ID
                    completion(nil)
                } else {
                    completion(error)
                }
            }
        } catch {
            completion(.failedDecodeData(error))
        }
    }
    
    func pullNotes(completion: @escaping (_ result: [Note]?, _ error: GistServiceErrors?) -> Void) {
        isNotebookCreated { (result, error) in
            if result {
                GistService.shared.get(with: self.gistId) { (result, error) in
                    guard let gist = result else {
                        completion(nil, error)
                        return
                    }
                    do {
                        let notes = try self.parseNotes(from: gist)
                        completion(notes, nil)
                    } catch {
                        completion(nil, .failedDecodeData(error))
                    }
                }
            } else {
                self.createGist { error in
                    if error != nil {
                        completion(nil, error)
                    } else {
                        completion([], nil)
                    }
                }
            }
        }
    }
    
    func pushNotes(_ notes: [Note], completion: @escaping (_ result: Bool, _ error: GistServiceErrors?) -> Void) {
        do {
            let gistCreator = try createGistCreator(with: notes)
            isNotebookCreated { (result, error) in
                if result {
                    GistService.shared.patch(with: self.gistId, gist: gistCreator) { error in
                        if error != nil {
                            completion(false, error)
                        } else {
                            completion(true, nil)
                        }
                    }
                } else {
                    self.createGist(with: notes) { error in
                        if error == nil {
                            completion(true, nil)
                        } else {
                            completion(false, error)
                        }
                    }
                }
            }
        } catch {
            completion(false, .failedEncodeData(error))
        }
    }
    
}
