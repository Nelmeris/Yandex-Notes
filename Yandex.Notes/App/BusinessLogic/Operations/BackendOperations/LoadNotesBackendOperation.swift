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
    case failure(GistServiceError)
}

class LoadNotesBackendOperation: BaseBackendOperation {
    
    private(set) var result: LoadNotesBackendResult? { didSet { finish() } }
    private let gistForNotesService = GistForNotesService()
    
    override init(title: String? = nil, id: Int? = nil) {
        super.init(title: title ?? "Load notes from Backend", id: id)
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        gistForNotesService.pullNotes { result, error in
            guard let gistContainer = result else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(gistContainer)
        }
    }
    
    override func cancel() {
        gistForNotesService.cancelAllOperations()
        super.cancel()
    }
    
}
