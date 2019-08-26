//
//  PullNotesForGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 23/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum PullNotesGistOperationResult {
    case success(Gist)
    case failture
    case failtureRequest(NetworkError)
}

class GetGistForNotesOperation: BaseGistForNotesOperation {
    
    private var loadGistOperation: LoadGistsOperation?
    private var getGistOperation: GetGistOperation?
    
    private(set) var result: GetGistForNotesOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    init(id: Int? = nil) {
        let id = AsyncOperationID(number: id, title: "Get gist \"for notes\"")
        super.init(id: id)
    }
    
    private func searchGist(for q: String, in gists: [Gist]) -> Gist? {
        for gist in gists {
            if gist.description == q {
                return gist
            }
            for (fileName, _) in gist.files {
                if fileName == q {
                    return gist
                }
            }
        }
        return nil
    }
    
    private func loadGists(completion: @escaping (LoadGistsOperationResult) -> ()) {
        let loadGistsOperation = LoadGistsOperation()
        loadGistsOperation.completionBlock = {
            let result = loadGistsOperation.result!
            completion(result)
        }
        queue.addOperation(loadGistsOperation)
        self.loadGistOperation = loadGistsOperation
    }
    
    func getGist(with gistId: String, completion: @escaping (GetGistOperationResult) -> ()) {
        let getGistOperation = GetGistOperation(gistId: gistId)
        getGistOperation.completionBlock = {
            guard let result = getGistOperation.result else { return }
            completion(result)
        }
        queue.addOperation(getGistOperation)
        self.getGistOperation = getGistOperation
    }
    
    override func main() {
        if let gistId = BaseGistForNotesOperation.gistId {
            getGist(with: gistId) { result in
                switch result {
                case .success(let gist):
                    self.result = .success(gist)
                case .failture:
                    self.result = .failture
                case.failtureRequest(let error):
                    self.result = .failtureRequest(error)
                }
            }
        } else {
            loadGists() { result in
                switch result {
                case .success(let gists):
                    guard let gist = self.searchGist(for: BaseGistForNotesOperation.gistName, in: gists) else {
                        self.result = .failture
                        return
                    }
                    self.result = .success(gist)
                case .failture(let error):
                    self.result = .failtureRequest(error)
                }
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        loadGistOperation?.cancel()
        getGistOperation?.cancel()
    }
    
}

