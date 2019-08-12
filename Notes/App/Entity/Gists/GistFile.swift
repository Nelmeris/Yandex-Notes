//
//  GistFile.swift
//  Gists
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct GistFile: Codable {
    
    let filename: String
    let type: String
    let language: String?
    let rawUrl: URL
    let size: Int
    
    let content: String?
    
    enum CodingKeys: String, CodingKey {
        case filename
        case type
        case language
        case rawUrl = "raw_url"
        case size
        case content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.filename = try container.decode(String.self, forKey: .filename)
        self.type = try container.decode(String.self, forKey: .type)
        self.language = try? container.decode(String.self, forKey: .language)
        
        self.rawUrl = URL(string: try container.decode(String.self, forKey: .rawUrl))!
        self.size = try container.decode(Int.self, forKey: .size)
        self.content = try? container.decode(String.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filename, forKey: .filename)
        try container.encode(type, forKey: .type)
        try container.encode(language, forKey: .language)
        try container.encode(rawUrl.absoluteString, forKey: .rawUrl)
        try container.encode(size, forKey: .size)
        try container.encode(content, forKey: .content)
    }
    
}
