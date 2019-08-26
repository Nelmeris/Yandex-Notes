//
//  SaveNotesBackendOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SaveNotesBackendResult {
    case success
    case failure
    case failureRequest(NetworkError)
}

class SaveNotesBackendOperation: BaseBackendOperation {
    
    private(set) var result: SaveNotesBackendResult? { didSet { finish() } }
    private var pushNotesToGist: PushNotesGistOperation?
    
    private var notes: [Note]
    
    init(notes: [Note], title: String? = nil, id: Int? = nil) {
        self.notes = notes
        super.init(title: title ?? "Save notes to Backend", id: id)
        
        self.pushNotesToGist = PushNotesGistOperation(notes: notes, id: self.id?.number)
        commonQueue.addOperation(pushNotesToGist!)
        addDependency(pushNotesToGist!)
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        guard let result = pushNotesToGist?.result else { return }
        switch result {
        case .success:
            self.result = .success
        case .failure:
            self.result = .failure
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    override func cancel() {
        super.cancel()
        pushNotesToGist?.cancel()
    }
    
}
