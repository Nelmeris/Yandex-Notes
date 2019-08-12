//
//  GistFile.swift
//  Gists
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct GistFile: Decodable {
    
    let filename: String
    let type: String
    let language: String?
    let raw_url: URL
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case filename
        case type
        case language
        case rawUrl = "raw_url"
        case size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.filename = try container.decode(String.self, forKey: .filename)
        self.type = try container.decode(String.self, forKey: .type)
        self.language = try? container.decode(String.self, forKey: .language)
        
        self.raw_url = URL(string: try container.decode(String.self, forKey: .rawUrl))!
        self.size = try container.decode(Int.self, forKey: .size)
    }
    
}
