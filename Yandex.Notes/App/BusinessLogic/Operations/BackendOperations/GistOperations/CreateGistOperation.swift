//
//  CreateGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum CreateGistOperationResult {
    case success(Gist)
    case failure
    case failureRequest(NetworkError)
}

class CreateGistOperation: BaseGistOperation {
    
    private let gistCreator: GistCreator
    
    private(set) var result: CreateGistOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    init(gistCreator: GistCreator, title: String? = nil, id: Int? = nil) {
        self.gistCreator = gistCreator
        
        super.init(title: title ?? "Create gist", id: id)
    }
    
    private func createGist(with data: Data) {
        let container = GistRequestContainer(path: "gists", method: .post, data: data)
        executeRequest(container: container) { result in
            switch result {
            case .success(let data):
                do {
                    let newGist = try JSONDecoder().decode(Gist.self, from: data)
                    self.result = .success(newGist)
                } catch {
                    self.result = .failure
                }
            case .failure(let error):
                self.result = .failureRequest(error)
            }
        }
    }
    
    override func main() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(gistCreator)
        createGist(with: data)
    }
    
    override func cancel() {
        super.cancel()
        self.executeOperation?.cancel()
    }
    
}
