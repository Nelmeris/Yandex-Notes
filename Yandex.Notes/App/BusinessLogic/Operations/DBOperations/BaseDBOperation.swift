//
//  BaseDBOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

let dbQueue = OperationQueue()

class BaseDBOperation: AsyncOperation {
    
    let noteCDService: NoteCoreDataService
    
    init(title: String, context: NSManagedObjectContext) {
        self.noteCDService = NoteCoreDataService(context: context)
        super.init(title: title)
    }
    
}
