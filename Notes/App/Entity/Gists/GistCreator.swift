//
//  GistCreator.swift
//  Notes
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

struct GistCreator: Codable {
    let `public`: Bool?
    let description: String
    let files: [String: GistFileCreator]
}
