//
//  RewriteDBOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

enum RewriteDBOperationResult {
    case success
    case failture(Error)
}

class RewriteDBOperation: BaseDBOperation {
    
    var notes: [Note]
    private(set) var result: RewriteDBOperationResult? {
        didSet {
            finish()
        }
    }
    
    init(notes: [Note],
         context: NSManagedObjectContext) {
        self.notes = notes
        super.init(title: "Rewrite DataBase", context: context)
    }
    
    override func main() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        noteCDService.removeAll(queue: queue) { [weak self] error in
            guard let `self` = self else { return }
            if let error = error {
                self.result = .failture(error)
                return
            }
            self.noteCDService.save(self.notes, queue: queue) { error in
                if let error = error {
                    self.result = .failture(error)
                } else {
                    self.result = .success
                }
            }
        }
    }
    
}
