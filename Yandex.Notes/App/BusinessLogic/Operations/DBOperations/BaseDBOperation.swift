//
//  BaseDBOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import CoreData

class BaseDBOperation: AsyncOperation {
    
    let noteCDService: NoteCoreDataService
    
    static var queue = OperationQueue()
    
    init(context: NSManagedObjectContext, title: String, id: Int? = nil) {
        self.noteCDService = NoteCoreDataService(context: context)
        let id = AsyncOperationID(number: id, title: title)
        super.init(id: id)
    }
    
}
