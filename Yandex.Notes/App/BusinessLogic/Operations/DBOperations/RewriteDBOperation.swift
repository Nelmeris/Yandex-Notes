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
    case failure(Error)
}

class RewriteDBOperation: BaseDBOperation {
    
    var notes: [Note]
    private(set) var result: RewriteDBOperationResult? { didSet { finish() } }
    
    init(notes: [Note],
         context: NSManagedObjectContext, title: String? = nil, id: Int? = nil) {
        self.notes = notes
        super.init(context: context, title: title ?? "Rewrite DataBase", id: id)
    }
    
    override func main() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        guard !self.isCancelled else { return }
        noteCDService.rewrite(for: notes, queue: queue) { [weak self] error in
            guard let `self` = self else { return }
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success
            }
        }
    }
    
}
