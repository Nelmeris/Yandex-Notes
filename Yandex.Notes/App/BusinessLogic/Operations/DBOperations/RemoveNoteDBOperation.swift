//
//  RemoveNoteDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum RemoveNoteDBOperationResult {
    case success
    case failture(Error)
}

class RemoveNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    private(set) var result: RemoveNoteDBOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         context: NSManagedObjectContext) {
        self.note = note
        super.init(title: "Remove note from DataBase", context: context)
    }
    
    override func main() {
        noteCDService.remove(note, queue: DispatchQueue.global(qos: .userInitiated)) { error in
            if let error = error {
                self.result = .failture(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
