//
//  URLSessionDataTaskUpdate.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct URLResponseErrorContainer {
    let errorDescription: String
    let statusCode: Int
}

enum URLResponseResult {
    case success(data: Data, statusCode: Int)
    case failture(NetworkError)
}

extension URLSession {
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (URLResponseResult) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                completionHandler(.failture(.failedRequest(.noConnection)))
                return
            }
            let statusCode = response.statusCode
            if let error = error {
                let container = URLResponseErrorContainer(errorDescription: error.localizedDescription, statusCode: response.statusCode)
                switch response.statusCode {
                case ..<400:
                    completionHandler(.failture(.failedResponse(.redirection(container))))
                case 400..<500:
                    completionHandler(.failture(.failedResponse(.clientError(container))))
                case 500...:
                    completionHandler(.failture(.failedResponse(.serverError(container))))
                default:
                    fatalError("Unknown HTTP status code")
                }
            } else {
                guard let data = data, (200..<300).contains(statusCode) else {
                    completionHandler(.failture(.failedRequest(.unexpectedError(response: response))))
                    return
                }
                completionHandler(.success(data: data, statusCode: response.statusCode))
            }
        }
    }
    
}
