//
//  GistServiceErrors.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum GistServiceErrors: Error {
    case failedCreation
    case failedSave
    case failedPatch
    case failedLoad
    case failedGet
    case failedSearch
    case failedDecodeData(Error)
    case failedEncodeData(Error)
    case failedNetwork(NetworkError)
    case invalidToken(String)
    case noToken
}
