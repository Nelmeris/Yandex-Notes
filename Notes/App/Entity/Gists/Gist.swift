//
//  Gist.swift
//  Gists
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct Gist: Decodable {
    
    let url: URL
    let forksUrl: URL
    let commitsUrl: URL
    
    let id: String
    let nodeId: String
    
    let gitPullUrl: URL
    let gitPushUrl: URL
    let htmlUrl: URL
    
    let files: [String: GistFile]
    
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    let description: String
    let comments: Int
    let commentsUrl: URL
    
    let owner: GistOwner
    
    let truncated: Bool
    
    enum CodingKeys: String, CodingKey {
        case url
        case id
        case files
        case isPublic = "public"
        case description
        case comments
        case owner
        case truncated
        
        case forksUrl = "forks_url"
        case nodeId = "node_id"
        case gitPullUrl = "git_pull_url"
        case gitPushUrl = "git_push_url"
        case htmlUrl = "html_url"
        case commitsUrl = "commits_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case commentsUrl = "comments_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.url = URL(string: try container.decode(String.self, forKey: .url))!
        self.forksUrl = URL(string: try container.decode(String.self, forKey: .forksUrl))!
        self.commitsUrl = URL(string: try container.decode(String.self, forKey: .commitsUrl))!
        
        self.id = try container.decode(String.self, forKey: .id)
        self.nodeId = try container.decode(String.self, forKey: .nodeId)
        
        self.gitPullUrl = URL(string: try container.decode(String.self, forKey: .gitPullUrl))!
        self.gitPushUrl = URL(string: try container.decode(String.self, forKey: .gitPushUrl))!
        self.htmlUrl = URL(string: try container.decode(String.self, forKey: .htmlUrl))!
        
        self.files = try container.decode([String: GistFile].self, forKey: .files)
        
        self.isPublic = try container.decode(Bool.self, forKey: .isPublic)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        self.createdAt = dateFormatter.date(from: try container.decode(String.self, forKey: .createdAt))!
        self.updatedAt = dateFormatter.date(from: try container.decode(String.self, forKey: .updatedAt))!
        
        self.description = try container.decode(String.self, forKey: .description)
        self.comments = try container.decode(Int.self, forKey: .comments)
        self.commentsUrl = URL(string: try container.decode(String.self, forKey: .commentsUrl))!
        
        self.owner = try container.decode(GistOwner.self, forKey: .owner)
        
        self.truncated = try container.decode(Bool.self, forKey: .truncated)
    }
    
}
