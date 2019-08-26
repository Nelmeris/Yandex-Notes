//
//  BaseGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 22/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum GistRequestResult {
    case success(Data)
    case failure(NetworkError)
}

class BaseGistOperation: AsyncOperation {
    
    static let queue = OperationQueue()
    private let executeQueue = ExecuteRequestOperation.queue
    var executeOperation: ExecuteRequestOperation?
    
    func executeRequest(container: GistRequestContainer, completion: @escaping (GistRequestResult) -> ()) {
        let gistRequestManager = GistRequestManager(container: container)
        gistRequestManager.create { request in
            self.executeOperation = ExecuteRequestOperation(request: request)
            self.executeOperation?.completionBlock = {
                guard let result = self.executeOperation?.result else { return }
                guard !self.isCancelled else { return }
                switch result {
                case .success(let data, statusCode: let code):
                    print("Network request success. Status code: \(code)")
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            guard !self.isCancelled else { return }
            self.executeQueue.addOperation(self.executeOperation!)
        }
        
    }
    
    init(title: String, id: Int? = nil) {
        let id = AsyncOperationID(number: id, title: title)
        super.init(id: id)
    }
    
}
