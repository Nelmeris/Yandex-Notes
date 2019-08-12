//
//  URLSessionDataTaskUpdate.swift
//  Notes
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum URLResponseResult {
    case success(data: Data, statusCode: Int)
    case redirection(error: Error, statusCode: Int)
    case clientError(error: Error, statusCode: Int)
    case serverError(error: Error, statusCode: Int)
    case unknownError(error: Error)
    case unexpectedError(response: HTTPURLResponse)
}

extension URLSession {
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (URLResponseResult) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else { return }
            let statusCode = response.statusCode
            if let error = error {
                switch response.statusCode {
                case 300..<400:
                    completionHandler(.redirection(error: error, statusCode: statusCode))
                case 400..<500:
                    completionHandler(.clientError(error: error, statusCode: statusCode))
                case 500..<600:
                    completionHandler(.serverError(error: error, statusCode: statusCode))
                default:
                    completionHandler(.unknownError(error: error))
                }
            } else {
                guard let data = data, (200..<300).contains(statusCode) else {
                    completionHandler(.unexpectedError(response: response))
                    return
                }
                completionHandler(.success(data: data, statusCode: response.statusCode))
            }
        }
    }
    
}
