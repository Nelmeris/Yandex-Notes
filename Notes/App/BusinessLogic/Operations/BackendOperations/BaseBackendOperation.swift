//
//  BaseBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

let backendQueue = OperationQueue()

class BaseBackendOperation: AsyncOperation {
    
    let jsonGistFileName = "ios-course-notes-db"
    let gitHubAPIURL = "https://api.github.com/"
    
    let token: String = "8c142617e960853472647377ea0ea5bf031197ee"
    let gistId: String = "17456006ebdf32266e5054f32c081387"
    
}
