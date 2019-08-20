//
//  NetworkError.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum NetworkError {
    case failedRequest(URLRequestError)
    case failedResponse(URLResponseError)
}
