//
//  GistNotesContainer.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct GistNotesContainer: Codable {
    
    let notes: [Note]
    let lastUpdateDate: Date
    
    private let dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    enum CodingKeys: String, CodingKey {
        case notes
        case lastUpdateDate = "last_update_date"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.notes = try container.decode([Note].self, forKey: .notes)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        self.lastUpdateDate = dateFormatter.date(from: try container.decode(String.self, forKey: .lastUpdateDate))!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(notes, forKey: .notes)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        try container.encode(dateFormatter.string(from: lastUpdateDate), forKey: .lastUpdateDate)
    }
    
    init(notes: [Note], createdDate: Date) {
        self.notes = notes
        self.lastUpdateDate = createdDate
    }
    
}
