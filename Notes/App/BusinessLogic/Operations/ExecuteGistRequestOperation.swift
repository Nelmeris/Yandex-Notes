//
//  ExecuteGistRequestOperation.swift
//  Notes
//
//  Created by Артем Куфаев on 13/08/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
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
    
    private func createRequest(completion: @escaping (URLRequest) -> Void) throws {
        let urlPath = "\(GistService.shared.gitHubAPIURL)/\(path)"
        guard let url = URL(string: urlPath) else { throw URLRequestError.invalidUrlPath(urlPath) }
        guard let token = GistService.shared.accessToken else {
            let authVC = AuthViewController()
            
            DispatchQueue.main.async {
                if let visibleViewController = getVisibleViewController() {
                    visibleViewController.present(authVC, animated: true)
                } else {
                    UIApplication.shared.keyWindow?.rootViewController = authVC
                }
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: GistService.shared.notificationKey), object: nil, queue: nil) { _ in
                try! self.createRequest { completion($0) }
            }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = method.rawValue
        request.httpBody = data
        completion(request)
    }
    
    private func executeRequest(completion: @escaping (URLResponseResult) -> Void) throws {
        try createRequest { request in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            
            print("\(dateFormatter.string(from: Date())): Request \(self.method.rawValue)/\(request.url!.absoluteString)")
            
            URLSession.shared.dataTask(with: request) { result in
                completion(result)
            }.resume()
        }
    }
    
    override func main() {
        do {
            try executeRequest { result in
                switch result {
                case .success(let container):
                    self.result = .success(container.data, statusCode: container.statusCode)
                case .failture(let error):
                    self.result = .failture(error)
                }
            }
        } catch {
            if let error = error as? URLRequestError {
                self.result = .failture(NetworkError.failedRequest(error))
            } else {
                self.result = .failture(NetworkError.failedRequest(.unknownError(error)))
            }
        }
    }
    
}
