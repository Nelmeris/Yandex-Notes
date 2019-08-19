//
//  SaveNoteDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum SaveNoteDBOperationResult {
    case success
    case failture(Error)
}

class SaveNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    private(set) var result: SaveNoteDBOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         context: NSManagedObjectContext) {
        self.note = note
        super.init(title: "Save note to DataBase", context: context)
    }
    
    override func main() {
        noteCDService.save(note, queue: DispatchQueue.global(qos: .userInitiated)) { error in
            if let error = error {
                self.result = .failture(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
