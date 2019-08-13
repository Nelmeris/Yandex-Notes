//
//  LoadNotesBackendOperation.swift
//  Notes
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
    
    private(set) var result: LoadNotesBackendResult? {
        didSet {
            finish()
        }
    }
    
    init() {
        super.init(title: "Load notes from Backend")
    }
    
    override func main() {
        GistForNotesService.shared.pullNotes { result, error in
            guard let gistContainer = result else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(gistContainer)
        }
    }
    
}
