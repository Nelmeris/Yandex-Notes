//
//  UIOperationResult.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum UIOperationResult {
    case success([Note])
    case backendFailure(dbNotes: [Note], error: NetworkError?)
    case dbFailure(Error)
}
