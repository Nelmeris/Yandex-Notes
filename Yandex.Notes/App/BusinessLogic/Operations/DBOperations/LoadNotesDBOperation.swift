//
//  LoadNotesDBOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum LoadNotesDBOperationResult {
    case success([Note])
    case failture(Error)
}

class LoadNotesDBOperation: BaseDBOperation {
    
    private(set) var result: LoadNotesDBOperationResult? { didSet { finish() } }
    
    override init(context: NSManagedObjectContext, title: String? = nil, id: Int? = nil) {
        super.init(context: context, title: title ?? "Load notes from DataBase", id: id)
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        do {
            let notes = try noteCDService.load()
            self.result = .success(notes)
        } catch {
            self.result = .failture(error)
        }
    }
    
}
