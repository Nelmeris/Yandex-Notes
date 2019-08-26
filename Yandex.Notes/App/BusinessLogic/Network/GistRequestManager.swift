//
//  GistRequestManager.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

enum GistRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

struct GistRequestContainer {
    let path: String
    let method: GistRequestMethod
    let data: Data?
}

class GistRequestManager {
    
    static let gitHubAPIURL = "https://api.github.com"
    static let notificationKey = "token_was_received"
    static let accessTokenKey = "access_token"
    
    static var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
            }
        }
    }
    
    private let container: GistRequestContainer
    
    init(container: GistRequestContainer) {
        self.container = container
    }
    
    private let requestTimeoutInterval: TimeInterval = 10
    
    private func getToken(completion: @escaping (_ token: String) -> ()) {
        let authVC = AuthViewController()
        
        DispatchQueue.main.async {
            let window = UIApplication.shared.keyWindow
            if let visibleViewController = window?.visibleViewController {
                visibleViewController.present(authVC, animated: true)
            } else {
                window?.rootViewController = authVC
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: GistRequestManager.notificationKey), object: nil, queue: nil) { notification in
            completion(notification.object as! String)
        }
    }
    
    private func getRequest(to url: URL, token: String, completion: @escaping (URLRequest) -> ()) {
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = container.method.rawValue
        request.httpBody = container.data
        request.timeoutInterval = requestTimeoutInterval
        completion(request)
    }
    
    func create(completion: @escaping (URLRequest) -> ()) {
        let url = URL(string: "\(GistRequestManager.gitHubAPIURL)/\(container.path)")!
        guard let token = GistRequestManager.accessToken else {
            self.getToken { token in
                self.getRequest(to: url, token: token) { completion($0) }
            }
            return
        }
        self.getRequest(to: url, token: token) { completion($0) }
    }
    
}
