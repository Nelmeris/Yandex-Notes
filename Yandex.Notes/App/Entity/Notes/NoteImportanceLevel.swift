//
//  NoteImportanceLevel.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 20/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum NoteImportanceLevel: Int, Codable {
    case insignificant, usual, critical // 0, 1, 2
}
