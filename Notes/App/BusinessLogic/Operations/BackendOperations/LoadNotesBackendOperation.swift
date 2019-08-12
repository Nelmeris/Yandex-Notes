//
//  LoadNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum LoadNotesBackendResult {
    case success([Note])
    case failure(NetworkError)
}

class LoadNotesBackendOperation: BaseBackendOperation {
    private(set) var result: LoadNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    private func createNewGist() {
        let gistFileCreator = GistFileCreator(content: "[]")
        let gistCreator = GistCreator(public: false, description: self.jsonGistFileName, files: [self.jsonGistFileName: gistFileCreator])
        
        GistService.shared.create(with: gistCreator) { result in // Создать его
            if let gist = result { // Если успешно
                gistId = gist.id // Сохранить ID
                self.result = .success([]) // Сбросить заметки
            } else {
                self.result = .failure(.unreachable)
            }
        }
    }
    
    private func pullNotes(from gist: Gist) {
        guard let gistFile = gist.files[self.jsonGistFileName],
            let gistFileContent = gistFile.content else { return }
        do {
            let data = gistFileContent.data(using: .utf8)
            let notes = try JSONDecoder().decode([Note].self, from: data!)
            self.result = .success(notes)
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
            GistService.shared.get(with: gist.id) { gist in
                self.pullNotes(from: gist!)
            }
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
                self.pullNotes(from: gist)
            }
        } else { // Если неизвестен Gist
            // Найти его
            search(for: jsonGistFileName)
        }
    }
}
