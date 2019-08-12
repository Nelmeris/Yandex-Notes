//
//  GistService.swift
//  Notes
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

class GistService {
    
    private init() {}
    static let shared = GistService()
    
    func load(completion: @escaping ([Note]?) -> Void) {
        
    }
    
    func save(notes: [Note]) {
    }
    
}
