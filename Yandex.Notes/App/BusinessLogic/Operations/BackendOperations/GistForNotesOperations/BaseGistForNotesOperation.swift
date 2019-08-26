//
//  BaseGistForNotesOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 23/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class BaseGistForNotesOperation: AsyncOperation {
    
    static let gistName = "ios-course-notes-db"
    static private let gistIdKey = "gist_for_notes_id"
    
    let queue: OperationQueue = BaseGistOperation.queue
    private var createGistOperation: CreateGistOperation?
    
    static var gistId: String? {
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
    
    func createGistCreator(with notes: [Note] = []) -> GistCreator {
        let gistContainer = GistNotesContainer(notes: notes, createdDate: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(gistContainer)
        let gistContent = String(data: data, encoding: .utf8)
        let gistFileCreator = GistFileCreator(content: gistContent!)
        let gistCreator = GistCreator(public: false, description: BaseGistForNotesOperation.gistName, files: [BaseGistForNotesOperation.gistName: gistFileCreator])
        return gistCreator
    }
    
    func parseNotes(from gist: Gist) throws -> GistNotesContainer? {
        guard let file = gist.files[BaseGistForNotesOperation.gistName],
            let content = file.content,
            let data = content.data(using: .utf8) else { return nil }
        let gistContainer = try JSONDecoder().decode(GistNotesContainer.self, from: data)
        return gistContainer
    }
    
    func createGist(with notes: [Note] = [], completion: @escaping (Gist?) -> ()) {
        let gistCreator = createGistCreator(with: notes)
        let createGistOperation = CreateGistOperation(gistCreator: gistCreator)
        createGistOperation.completionBlock = {
            guard let result = createGistOperation.result else { return }
            switch result {
            case .success(let gist):
                completion(gist)
            case .failureRequest(let error):
                print(error.localizedDescription)
                completion(nil)
            default: break
            }
        }
        queue.addOperation(createGistOperation)
        self.createGistOperation = createGistOperation
    }
    
    init(title: String, id: Int? = nil) {
        let id = AsyncOperationID(number: id, title: title)
        super.init(id: id)
    }
    
}
