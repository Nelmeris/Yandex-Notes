//
//  UpdateNotesDBOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 21/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum UpdateNotesDBOperationResult {
    case success
    case failture(Error)
}

class UpdateNotesDBOperation: BaseDBOperation {
    
    private let notes: [Note]
    private(set) var result: UpdateNoteDBOperationResult? { didSet { finish() } }
    
    init(notes: [Note],
         context: NSManagedObjectContext,
         title: String? = nil, id: Int? = nil) {
        self.notes = notes
        super.init(context: context, title: title ?? "Update notes in DataBase", id: id)
    }
    
    override func main() {
        noteCDService.update(notes, queue: DispatchQueue.global(qos: .userInitiated)) { error in
            if let error = error {
                self.result = .failture(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
