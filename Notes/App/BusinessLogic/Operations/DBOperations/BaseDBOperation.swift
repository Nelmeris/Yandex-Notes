//
//  BaseDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

let dbQueue = OperationQueue()

class BaseDBOperation: AsyncOperation {
    
    let notebook: FileNotebook
    
    init(title: String, notebook: FileNotebook) {
        self.notebook = notebook
        super.init(title: title)
    }
    
}
