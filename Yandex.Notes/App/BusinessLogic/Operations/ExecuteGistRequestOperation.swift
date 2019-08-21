//
//  ExecuteGistRequestOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation
import UIKit

enum RequestMethods: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

enum GistRequestResult {
    case success(Data, statusCode: Int)
    case failture(NetworkError)
}

class ExecuteGistRequestOperation: AsyncOperation {
    
    static let queue = OperationQueue()
    
    private let dispatchGroup = DispatchGroup()
    private let method: RequestMethods
    private let path: String
    private let data: Data?
    
    private let requestTimeoutInterval: TimeInterval = 10
    
    private var dataTask: URLSessionDataTask?
    
    private(set) var result: GistRequestResult? { didSet { finish() } }
    
    init(method: RequestMethods, path: String, data: Data? = nil) {
        self.method = method
        self.path = path
        self.data = data
        super.init()
    }
    
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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: GistService.notificationKey), object: nil, queue: nil) { notification in
            completion(notification.object as! String)
        }
    }
    
    private func getRequest(to url: URL, token: String, completion: @escaping (URLRequest) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = method.rawValue
        request.httpBody = data
        request.timeoutInterval = requestTimeoutInterval
        completion(request)
    }
    
    private let noConnectionTimeKey = "no_connection_time"
    private let noConnectionDelay: TimeInterval = 30
    
    private func createRequest(completion: @escaping (URLRequest?) -> ()) {
        if let udValue = UserDefaults.standard.value(forKey: noConnectionTimeKey),
            let noConnectionTime = udValue as? Date {
            if Date().timeIntervalSince(noConnectionTime) < noConnectionDelay {
                completion(nil)
                return
            }
        }
        Reachability.isConnectedToNetwork { result in
            guard result else {
                completion(nil)
                UserDefaults.standard.set(Date(), forKey: self.noConnectionTimeKey)
                return
            }
            let url = URL(string: "\(GistService.gitHubAPIURL)/\(self.path)")!
            guard let token = GistService.accessToken else {
                self.getToken { token in
                    self.getRequest(to: url, token: token) { request in
                        completion(request)
                    }
                }
                return
            }
            self.getRequest(to: url, token: token) { request in
                completion(request)
            }
        }
    }
    
    private func executeRequest(completion: @escaping (URLResponseResult) -> Void) {
        createRequest { request in
            guard let request = request else {
                completion(.failture(.failedRequest(.noConnection)))
                return
            }
            
            self.dataTask = URLSession.shared.dataTask(with: request) { result in
                completion(result)
            }
            self.dataTask?.resume()
        }
    }
    
    override func main() {
        executeRequest { result in
            switch result {
            case .success(let container):
                self.result = .success(container.data, statusCode: container.statusCode)
            case .failture(let error):
                self.result = .failture(error)
            }
        }
    }
    
    override func cancel() {
        dataTask?.cancel()
        super.cancel()
    }
    
}
