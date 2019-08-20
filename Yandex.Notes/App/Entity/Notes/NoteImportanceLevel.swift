//
//  NoteImportanceLevel.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 20/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

enum NoteImportanceLevel: Int, Codable {
    case insignificant, usual, critical // 0, 1, 2
}
