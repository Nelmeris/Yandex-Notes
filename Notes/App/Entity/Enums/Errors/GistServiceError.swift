//
//  GistServiceError.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum GistServiceError: Error {
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
