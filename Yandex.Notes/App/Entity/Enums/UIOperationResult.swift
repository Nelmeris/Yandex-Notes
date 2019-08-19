//
//  UIOperationResult.swift
//  Notes
//
//  Created by Артем Куфаев on 19/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum UIOperationResult {
    case success([Note])
    case backendFailture(dbNotes: [Note], error: GistServiceError)
    case dbFailture(Error)
}
