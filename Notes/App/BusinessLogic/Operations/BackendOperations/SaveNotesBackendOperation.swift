//
//  SaveNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SaveNotesBackendResult {
    case success
    case failure(GistServiceErrors)
}

class SaveNotesBackendOperation: BaseBackendOperation {
    private(set) var result: SaveNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    private var notes: [Note]?
    
    init(notes: [Note]) {
        self.notes = notes
        super.init()
    }
    
    override func main() {
        print("Start save to Backend operation")
        GistForNotesService.shared.pushNotes(notes ?? []) { (result, error) in
            if result {
                self.result = .success
            } else {
                self.result = .failure(error!)
            }
        }
    }
}
