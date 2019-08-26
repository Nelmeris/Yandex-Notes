//
//  LoadNotesBackendOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum LoadNotesBackendResult {
    case success(GistNotesContainer)
    case failure
    case failureRequest(NetworkError)
}

class LoadNotesBackendOperation: BaseBackendOperation {
    
    var pullNotesFromGist: PullNotesGistOperation?
    
    private(set) var result: LoadNotesBackendResult? { didSet { finish() } }
    
    override init(title: String? = nil, id: Int? = nil) {
        super.init(title: title ?? "Load notes from Backend", id: id)
        
        pullNotesFromGist = PullNotesGistOperation(id: self.id?.number)
        commonQueue.addOperation(pullNotesFromGist!)
        addDependency(pullNotesFromGist!)
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        guard let result = pullNotesFromGist?.result else { return }
        switch result {
        case .success(let container):
            self.result = .success(container)
        case .failure:
            self.result = .failure
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    override func cancel() {
        super.cancel()
        pullNotesFromGist?.cancel()
    }
    
}
