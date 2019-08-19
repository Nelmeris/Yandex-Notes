//
//  SyncNotesOperation.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum SyncNotesResult {
    case success
    case failure(GistServiceErrors)
}

class SyncNotesOperation: BaseBackendOperation {
    
    private(set) var result: SyncNotesResult? {
        didSet {
            finish()
        }
    }
    
    private var notes: [Note]
    
    init(notes: [Note]) {
        self.notes = notes
        super.init(title: "Sync notes with Backend")
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
    
}
