//
//  GetGistForNotesOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 23/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum GetGistForNotesOperationResult {
    case success(Gist)
    case failure
    case failureRequest(NetworkError)
}

class GetGistForNotesOperation: BaseGistForNotesOperation {
    
    private var loadGists: LoadGistsOperation?
    private var getGist: GetGistOperation?
    
    private(set) var result: GetGistForNotesOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    override init(title: String? = nil, id: Int? = nil) {
        super.init(title: title ?? "Get gist \"for notes\"", id: id)
        
        if let gistId = BaseGistForNotesOperation.gistId {
            let getGistOperation = GetGistOperation(gistId: gistId, id: self.id?.number)
            let getGistOperationCompletion = BlockOperation {
                guard let result = getGistOperation.result else { return }
                switch result {
                case .failureRequest(_), .failure:
                    BaseGistForNotesOperation.gistId = nil
                    self.startLoad()
                default: break
                }
            }
            self.getGist = getGistOperation
            getGistOperationCompletion.addDependency(getGistOperation)
            commonQueue.addOperation(getGistOperationCompletion)
            addDependency(getGistOperation)
            queue.addOperation(getGistOperation)
        } else {
            startLoad()
        }
    }
    
    private func startLoad() {
        let loadGistsOperation = LoadGistsOperation(id: self.id?.number)
        self.loadGists = loadGistsOperation
        addDependency(loadGistsOperation)
        queue.addOperation(loadGistsOperation)
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
    
    override func main() {
        if let loadGistsResult = loadGists?.result {
            switch loadGistsResult {
            case .success(let gists):
                guard let gist = self.searchGist(for: BaseGistForNotesOperation.gistName, in: gists) else {
                    self.result = .failure
                    return
                }
                BaseGistForNotesOperation.gistId = gist.id
                self.result = .success(gist)
            case .failure:
                self.result = .failure
            case .failureRequest(let error):
                self.result = .failureRequest(error)
            }
        } else if let getGistResult = getGist?.result {
            switch getGistResult {
            case .success(let gist):
                self.result = .success(gist)
            case .failure:
                self.result = .failure
            case.failureRequest(let error):
                self.result = .failureRequest(error)
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        loadGists?.cancel()
        getGist?.cancel()
    }
    
}
