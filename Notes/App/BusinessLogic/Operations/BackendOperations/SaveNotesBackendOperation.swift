//
//  SaveNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SaveNotesBackendResult {
    case success
    case failure(NetworkError)
}

class SaveNotesBackendOperation: BaseBackendOperation {
    private(set) var result: SaveNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    private var notes: [Note]?
    
    init(notes: [Note]) {
        self.notes = notes
        super.init()
    }
    
    private func getGistCreator(from notes: [Note]) throws -> GistCreator {
        let data = try JSONEncoder().encode(notes)
        let gistContent = String(data: data, encoding: .utf8)
        let gistFileCreator = GistFileCreator(content: gistContent!)
        let gistCreator = GistCreator(public: nil, description: jsonGistFileName, files: [jsonGistFileName: gistFileCreator])
        return gistCreator
    }
    
    private func createNewGist() {
        do {
            let gistCreator = try getGistCreator(from: notes!)
            GistService.shared.create(with: gistCreator) { result in // Создать его
                if let gist = result { // Если успешно
                    gistId = gist.id // Сохранить ID
                    self.result = .success
                } else {
                    self.result = .failure(.unreachable)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func pushNotes(to gist: Gist) {
        do {
            let gistCreator = try getGistCreator(from: notes!)
            GistService.shared.patch(with: gist.id, gist: gistCreator) { result in
                if result {
                    self.result = .success
                } else {
                    self.result = .failure(.unreachable)
                }
            }
        } catch {
            print(error.localizedDescription)
            self.result = .failure(.unreachable)
        }
    }
    
    private func search(for q: String) {
        GistService.shared.search(for: jsonGistFileName) { result in
            // Если не найден
            guard let gist = result else {
                self.createNewGist()
                return
            }
            // Если найден
            gistId = gist.id
            self.pushNotes(to: gist)
        }
    }
    
    override func main() {
        // Если gist id известен
        if let gistId = gistId {
            // Получить его данные
            GistService.shared.get(with: gistId) { gist in
                guard let gist = gist else { // Если gist id ошибочен
                    self.search(for: self.jsonGistFileName)
                    return
                }
                self.pushNotes(to: gist)
            }
        } else { // Если неизвестен Gist
            // Найти его
            search(for: jsonGistFileName)
        }
    }
}
