//
//  GistOwner.swift
//  Gists
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

struct GistOwner: Codable {
    
    let login: String
    
    let id: Int
    let nodeId: String
    
    let avatarUrl: URL
    let gravatarId: String
    
    let url: URL
    let htmlUrl: URL
    
    let followersUrl: URL
    let followingUrl: URL?
    
    let gistsUrl: URL?
    let starredUrl: URL?
    
    let subscriptionsUrl: URL
    let organizationsUrl: URL
    
    let reposUrl: URL
    let eventsUrl: URL?
    let receivedEventsUrl: URL
    
    let type: String
    
    let siteAdmin: Bool?
    
    enum CodingKeys: String, CodingKey {
        case login, id, url, type
        case nodeId = "node_id"
        case avatarUrl = "avatar_url"
        case gravatarId = "gravatar_id"
        case htmlUrl = "html_url"
        case followersUrl = "followers_url"
        case followingUrl = "following_url"
        case gistsUrl = "gists_url"
        case starredUrl = "starred_url"
        case subscriptionsUrl = "subscriptions_url"
        case organizationsUrl = "organizations_url"
        case reposUrl = "repos_url"
        case eventsUrl = "events_url"
        case receivedEventsUrl = "received_events_url"
        case siteAdmin = "siteAdmin"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.login = try container.decode(String.self, forKey: .login)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.nodeId = try container.decode(String.self, forKey: .nodeId)
        
        self.avatarUrl = URL(string: try container.decode(String.self, forKey: .avatarUrl))!
        self.gravatarId = try container.decode(String.self, forKey: .gravatarId)
        
        self.url = URL(string: try container.decode(String.self, forKey: .url))!
        self.htmlUrl = URL(string: try container.decode(String.self, forKey: .htmlUrl))!
        
        self.followersUrl = URL(string: try container.decode(String.self, forKey: .followersUrl))!
        self.followingUrl = URL(string: (try? container.decode(String.self, forKey: .followingUrl)) ?? "")
        
        self.gistsUrl = URL(string: (try? container.decode(String.self, forKey: .gistsUrl)) ?? "")
        self.starredUrl = URL(string: (try? container.decode(String.self, forKey: .starredUrl)) ?? "")
        
        self.subscriptionsUrl = URL(string: try container.decode(String.self, forKey: .subscriptionsUrl))!
        self.organizationsUrl = URL(string: try container.decode(String.self, forKey: .organizationsUrl))!
        
        self.reposUrl = URL(string: try container.decode(String.self, forKey: .reposUrl))!
        self.eventsUrl = URL(string: (try? container.decode(String.self, forKey: .eventsUrl)) ?? "")
        self.receivedEventsUrl = URL(string: try container.decode(String.self, forKey: .receivedEventsUrl))!
        
        self.type = try container.decode(String.self, forKey: .type)
        
        self.siteAdmin = try? container.decode(Bool.self, forKey: .siteAdmin)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(login, forKey: .login)
        
        try container.encode(id, forKey: .id)
        try container.encode(nodeId, forKey: .nodeId)
        
        try container.encode(avatarUrl.absoluteString, forKey: .avatarUrl)
        try container.encode(gravatarId, forKey: .gravatarId)
        
        try container.encode(url.absoluteString, forKey: .url)
        try container.encode(htmlUrl.absoluteString, forKey: .htmlUrl)
        
        try container.encode(followersUrl.absoluteString, forKey: .followersUrl)
        try container.encode(followingUrl?.absoluteString, forKey: .followingUrl)
        
        try container.encode(gistsUrl?.absoluteString, forKey: .gistsUrl)
        try container.encode(starredUrl?.absoluteString, forKey: .starredUrl)
        
        try container.encode(subscriptionsUrl.absoluteString, forKey: .subscriptionsUrl)
        try container.encode(organizationsUrl.absoluteString, forKey: .organizationsUrl)
        
        try container.encode(reposUrl.absoluteString, forKey: .reposUrl)
        try container.encode(eventsUrl?.absoluteString, forKey: .eventsUrl)
        try container.encode(receivedEventsUrl.absoluteString, forKey: .receivedEventsUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(siteAdmin, forKey: .siteAdmin)
    }
    
}
