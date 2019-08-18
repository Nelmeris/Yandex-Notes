//
//  URLRequestError.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum URLRequestError: Error {
    case invalidUrlPath(String)
    case unknownError(Error)
    case unexpectedError(response: HTTPURLResponse)
}
