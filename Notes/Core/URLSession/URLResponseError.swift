//
//  URLResponseError.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum URLResponseError: Error, LocalizedError {
    case redirection(URLResponseErrorContainer)
    case clientError(URLResponseErrorContainer)
    case serverError(URLResponseErrorContainer)
    
    var localizedDescription: String {
        switch self {
        case .redirection(let container):
            return "Redirection. Status code: \(container.statusCode). Description: \(container.errorDescription)"
        case .clientError(let container):
            return "Client error. Status code: \(container.statusCode). Description: \(container.errorDescription)"
        case .serverError(let container):
            return "Server error. Status code: \(container.statusCode). Description: \(container.errorDescription)"
        }
    }
}
