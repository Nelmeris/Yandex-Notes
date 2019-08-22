//
//  SaveNoteDBOperation.swift
//  Yandex.Notes
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
         context: NSManagedObjectContext, title: String? = nil, id: Int? = nil) {
        self.note = note
        super.init(context: context, title: title ?? "Save not to DataBase", id: id)
    }
    
    override func main() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        guard !self.isCancelled else { return }
        noteCDService.save(note, queue: queue) { error in
            if let error = error {
                self.result = .failture(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
