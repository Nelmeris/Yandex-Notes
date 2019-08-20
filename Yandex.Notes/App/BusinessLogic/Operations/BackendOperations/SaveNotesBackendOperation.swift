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
    
    private(set) var result: SaveNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    var notes: [Note]
    
    init(notes: [Note]) {
        self.notes = notes
        super.init(title: "Save notes to Backend")
    }
    
    override func main() {
        GistForNotesService.shared.pushNotes(notes) { (result, error) in
            if result {
                self.result = .success
            } else {
                self.result = .failure(error!)
            }
        }
    }
    
    override func cancel() {
        GistForNotesService.shared.cancelLastOperation()
        super.cancel()
    }
    
}
