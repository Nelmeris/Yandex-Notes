//
//  BaseBackendOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

let backendQueue = OperationQueue()

class BaseBackendOperation: AsyncOperation {
    
    static var queue = OperationQueue()
    
    init(title: String, id: Int? = nil) {
        let id = AsyncOperationID(number: id, title: title)
        super.init(id: id)
    }
    
}
