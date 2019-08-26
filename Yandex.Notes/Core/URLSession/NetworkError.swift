//
//  NetworkError.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidUrlPath(String)
    case unknownError(Error)
    case unexpectedError(response: HTTPURLResponse)
    case noConnection
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
        case .noConnection:
            return "You aren't connected to the network"
        case .invalidUrlPath(let path):
            return "Invalid URL path: \(path)"
        case .unexpectedError(response: let httpResponse):
            return "Emergency in the http request. Status code: \(httpResponse.statusCode); \(httpResponse.allHeaderFields)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
