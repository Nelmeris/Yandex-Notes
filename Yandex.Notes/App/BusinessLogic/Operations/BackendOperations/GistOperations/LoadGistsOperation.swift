//
//  LoadGistsOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum LoadGistsOperationResult {
    case success([Gist])
    case failure
    case failureRequest(NetworkError)
}

class LoadGistsOperation: BaseGistOperation {
    
    private(set) var result: LoadGistsOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    override init(title: String? = nil, id: Int? = nil) {
        super.init(title: title ?? "Load gists", id: id)
    }
    
    override func main() {
        let container = GistRequestContainer(path: "gists", method: .get, data: nil)
        executeRequest(container: container) { result in
            switch result {
            case .success(let data):
                do {
                    let gists = try JSONDecoder().decode([Gist].self, from: data)
                    self.result = .success(gists)
                } catch {
                    self.result = .failure
                }
            case .failure(let error):
                self.result = .failureRequest(error)
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        self.executeOperation?.cancel()
    }
    
}
