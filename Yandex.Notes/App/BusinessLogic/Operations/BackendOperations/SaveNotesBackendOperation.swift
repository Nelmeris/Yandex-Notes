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
    case failure(GistServiceError)
}

class SaveNotesBackendOperation: BaseBackendOperation {
    
    private(set) var result: SaveNotesBackendResult? { didSet { finish() } }
    private let gistForNotesService = GistForNotesService()
    
    private var notes: [Note]
    
    init(notes: [Note], title: String? = nil, id: Int? = nil) {
        self.notes = notes
        super.init(title: title ?? "Save notes to Backend", id: id)
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        gistForNotesService.pushNotes(notes) { (result, error) in
            if result {
                self.result = .success
            } else {
                self.result = .failure(error!)
            }
        }
    }
    
    override func cancel() {
        gistForNotesService.cancelAllOperations()
        super.cancel()
    }
    
}
