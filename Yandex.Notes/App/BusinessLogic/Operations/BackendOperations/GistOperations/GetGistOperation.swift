//
//  GetGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum GetGistOperationResult {
    case success(Gist)
    case failure
    case failureRequest(NetworkError)
}

class GetGistOperation: BaseGistOperation {
    
    private(set) var result: GetGistOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    private let gistId: String
    
    init(gistId: String, title: String? = nil, id: Int? = nil) {
        self.gistId = gistId
        super.init(title: title ?? "Get gist", id: id)
    }
    
    override func main() {
        let container = GistRequestContainer(path: "gists/\(gistId)", method: .get, data: nil)
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
    
    override func cancel() {
        super.cancel()
        self.executeOperation?.cancel()
    }
    
}
