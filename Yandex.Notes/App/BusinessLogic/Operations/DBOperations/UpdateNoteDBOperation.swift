//
//  UpdateNoteDBOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum UpdateNoteDBOperationResult {
    case success
    case failture(Error)
}

class UpdateNoteDBOperation: BaseDBOperation {
    
    private let note: Note
    private(set) var result: UpdateNoteDBOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(note: Note,
         context: NSManagedObjectContext,
         title: String? = nil, id: Int? = nil) {
        self.note = note
        super.init(context: context, title: title ?? "Update note in DataBase", id: id)
    }
    
    override func main() {
        noteCDService.update(note, queue: DispatchQueue.global(qos: .userInitiated)) { error in
            if let error = error {
                self.result = .failture(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
