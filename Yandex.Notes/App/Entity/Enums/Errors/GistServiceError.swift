//
//  GistServiceError.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum GistServiceError: Error, LocalizedError {
    case failed(NetworkError)
    case failedSearch
    case failedDecodeData(Error)
    case failedEncodeData(Error)
    case invalidToken(String)
    case noToken
    
    var localizedDescription: String {
        switch self {
        case .failed(let error):
            switch error {
            case .failedRequest(let requestError):
                return requestError.localizedDescription
            case .failedResponse(let responseError):
                return responseError.localizedDescription
            }
//        case .failedCreation:
//            return "Unsuccessful creation the Gist"
//        case .failedSave:
//            return "Failed to save Gist"
//        case .failedPatch:
//            return "Unsuccessful creation of the Gist"
//        case .failedLoad:
//            return "Unsuccessful Gist patch"
//        case .failedGet:
//            return "Unsuccessful getting the Gist"
        case .failedSearch:
            return "Failid Gist search"
        case .failedDecodeData(let error):
            return "Error decoding Gist. Description: \(error.localizedDescription)"
        case .failedEncodeData(let error):
            return "Error encoding Gist. Description: \(error.localizedDescription)"
        case .invalidToken(let token):
            return "Token \"\(token)\" isn't valid"
        case .noToken:
            return "Token not found"
        }
    }
}
