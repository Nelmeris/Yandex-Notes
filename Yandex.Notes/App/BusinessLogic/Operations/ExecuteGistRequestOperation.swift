//
//  ExecuteGistRequestOperation.swift
//  Notes
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
    
    private let dispatchGroup = DispatchGroup()
    private let method: RequestMethods
    private let path: String
    private let data: Data?
    
    private let requestTimeoutInterval: TimeInterval = 10
    
    private(set) var result: GistRequestResult? {
        didSet {
            finish()
        }
    }
    
    init(method: RequestMethods, path: String, data: Data? = nil) {
        self.method = method
        self.path = path
        self.data = data
        super.init(title: "Execute Gist request")
    }
    
    private func getToken(completion: @escaping (_ token: String) -> ()) {
        let authVC = AuthViewController()
        
        DispatchQueue.main.async {
            if let visibleViewController = getVisibleViewController() {
                visibleViewController.present(authVC, animated: true)
            } else {
                UIApplication.shared.keyWindow?.rootViewController = authVC
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: GistService.shared.notificationKey), object: nil, queue: nil) { notification in
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
    
    private func createRequest(completion: @escaping (URLRequest?) -> Void) {
        Reachability.isConnectedToNetwork { result in
            guard result else {
                completion(nil)
                return
            }
            let url = URL(string: "\(GistService.shared.gitHubAPIURL)/\(self.path)")!
            guard let token = GistService.shared.accessToken else {
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            
            print("\(dateFormatter.string(from: Date())): Request \(self.method.rawValue)/\(request.url!.absoluteString)")
            
            URLSession.shared.dataTask(with: request) { result in
                completion(result)
            }.resume()
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
    
}
