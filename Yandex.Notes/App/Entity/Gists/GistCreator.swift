//
//  GistCreator.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct GistCreator: Codable {
    let `public`: Bool?
    let description: String
    let files: [String: GistFileCreator]
}
