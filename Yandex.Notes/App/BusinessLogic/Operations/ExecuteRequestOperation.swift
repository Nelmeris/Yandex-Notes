//
//  ExecuteRequestOperation.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

enum ExecuteRequestResult {
    case success(Data, statusCode: Int)
    case failure(NetworkError)
}

class ExecuteRequestOperation: AsyncOperation {
    
    static let queue = OperationQueue()
    
    private let request: URLRequest
    private var dataTask: URLSessionDataTask?
    
    private(set) var result: ExecuteRequestResult? { didSet { finish() } }
    
    private let noConnectionTimeKey = "no_connection_time"
    private let noConnectionDelay: TimeInterval = 30
    
    init(request: URLRequest) {
        self.request = request
        super.init()
    }
    
    private func executeRequest(completion: @escaping (URLResponseResult) -> Void) {
        if let udValue = UserDefaults.standard.value(forKey: noConnectionTimeKey),
            let noConnectionTime = udValue as? Date {
            if Date().timeIntervalSince(noConnectionTime) < noConnectionDelay {
                completion(.failure(.noConnection))
                return
            }
        }
        guard !self.isCancelled else { return }
        Reachability.isConnectedToNetwork { result in
            guard !self.isCancelled else { return }
            guard result else {
                completion(.failure(.noConnection))
                UserDefaults.standard.set(Date(), forKey: self.noConnectionTimeKey)
                return
            }
            self.dataTask = URLSession.shared.dataTask(with: self.request) { result in
                completion(result)
            }
            guard !self.isCancelled else { return }
            self.dataTask?.resume()
        }
    }
    
    override func main() {
        guard !self.isCancelled else { return }
        executeRequest { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let container):
                self.result = .success(container.data, statusCode: container.statusCode)
            case .failure(let error):
                self.result = .failure(error)
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        dataTask?.cancel()
    }
    
}
