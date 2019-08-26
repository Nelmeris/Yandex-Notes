//
//  PatchGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum PatchGistOperationResult {
    case success(Gist)
    case failure
    case failureRequest(NetworkError)
}

class PatchGistOperation: BaseGistOperation {
    
    private(set) var result: PatchGistOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    private let gistCreator: GistCreator
    private let gistId: String
    
    init(gistCreator: GistCreator, gistId: String, title: String? = nil, id: Int? = nil) {
        self.gistCreator = gistCreator
        self.gistId = gistId
        super.init(title: title ?? "Patch gist", id: id)
    }
    
    private func patchGist(with data: Data) {
        let container = GistRequestContainer(path: "gists/\(gistId)", method: .patch, data: data)
        executeRequest(container: container) { result in
            switch result {
            case .success(let data):
                do {
                    let gist = try JSONDecoder().decode(Gist.self, from: data)
                    self.result = .success(gist)
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
        patchGist(with: data)
    }
    
    override func cancel() {
        super.cancel()
        self.executeOperation?.cancel()
    }
    
}
