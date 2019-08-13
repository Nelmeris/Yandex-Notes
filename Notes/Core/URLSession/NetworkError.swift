//
//  NetworkError.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum NetworkError {
    case failedRequest(URLRequestError)
    case failedResponse(URLResponseError)
}
