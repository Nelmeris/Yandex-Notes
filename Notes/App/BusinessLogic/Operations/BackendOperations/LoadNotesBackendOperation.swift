//
//  LoadNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum LoadNotesBackendResult {
    case success([Note])
    case failure(GistServiceErrors)
}

class LoadNotesBackendOperation: BaseBackendOperation {
    private(set) var result: LoadNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    override func main() {
        print("Start load from Backend operation")
        GistForNotesService.shared.pullNotes { result, error in
            guard let notes = result else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(notes)
        }
    }
}
