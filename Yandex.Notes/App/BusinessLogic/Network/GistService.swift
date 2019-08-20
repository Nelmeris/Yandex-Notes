//
//  GistService.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class GistService {
    
    private init() {
        executeQueue.maxConcurrentOperationCount = 1
    }
    static let shared = GistService()
    
    let gitHubAPIURL = "https://api.github.com"
    let notificationKey = "token_was_received"
    
    let accessTokenKey = "access_token"
    
    var accessToken: String? {
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
    
    private let executeQueue = OperationQueue()
    
    enum ExecuteRequestResult {
        case success(Data)
        case failture(NetworkError)
        case closed
    }
    
    var operations: [ExecuteGistRequestOperation] = []
    
    private func executeRequest(with method: RequestMethods, path: String, data: Data? = nil, completion: @escaping (ExecuteRequestResult) -> ()) {
        let operation = ExecuteGistRequestOperation(method: method, path: path, data: data)
        operations.append(operation)
        operation.completionBlock = {
            self.operations.removeAll { $0 == operation }
            guard let result = operation.result else {
                completion(.closed)
                return
            }
            switch result {
            case .success(let data, statusCode: let code):
                print("Network request success. Status code: \(code)")
                completion(.success(data))
            case .failture(let error):
                switch error {
                case .failedRequest(let error):
                    print("Network request error. \(error.localizedDescription)")
                    completion(.failture(.failedRequest(error)))
                case .failedResponse(let error):
                    print("Network response error. \(error.localizedDescription)")
                    completion(.failture(.failedResponse(error)))
                }
            }
        }
        executeQueue.addOperation(operation)
    }
    
    // Создать новый Gist
    func create(with gist: GistCreator, completion: @escaping (_ data: Gist?, _ error: GistServiceError?) -> Void) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(gist)
            executeRequest(with: .post, path: "gists", data: data) { result in
                switch result {
                case.success(let data):
                    do {
                        let newGist = try JSONDecoder().decode(Gist.self, from: data)
                        completion(newGist, nil)
                    } catch {
                        completion(nil, .failedDecodeData(error))
                    }
                case .failture(let netError):
                    completion(nil, .failed(netError))
                case .closed:
                    completion(nil, .cancel)
                }
            }
        } catch {
            completion(nil, .failedEncodeData(error))
        }
    }
    
    // Обновить Gist по ID
    func patch(with gistId: String, gist: GistCreator, completion: @escaping (_ error: GistServiceError?) -> Void) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(gist)
            executeRequest(with: .patch, path: "gists/\(gistId)", data: data) { result in
                switch result {
                case .failture(let netError):
                    completion(.failed(netError))
                default:
                    completion(nil)
                }
            }
        } catch {
            completion(.failedEncodeData(error))
        }
    }
    
    // Загрузить все Gist's пользователя
    func load(completion: @escaping (_ data: [Gist]?, _ error: GistServiceError?) -> Void) {
        executeRequest(with: .get, path: "gists") { result in
            switch result {
            case .success(let data):
                do {
                    let gists = try JSONDecoder().decode([Gist].self, from: data)
                    completion(gists, nil)
                } catch {
                    completion(nil, .failedDecodeData(error))
                }
            case .failture(let netError):
                completion(nil, .failed(netError))
            case .closed:
                completion(nil, .cancel)
            }
        }
    }
    
    // Получить определенный Gist по ID
    func get(with gistId: String, completion: @escaping (_ data: Gist?, _ error: GistServiceError?) -> Void) {
        executeRequest(with: .get, path: "gists/\(gistId)") { result in
            switch result {
            case .success(let data):
                do {
                    let gist = try JSONDecoder().decode(Gist.self, from: data)
                    completion(gist, nil)
                } catch let error {
                    completion(nil, .failedDecodeData(error))
                }
            case .failture(let netError):
                completion(nil, .failed(netError))
            case .closed:
                completion(nil, .cancel)
            }
        }
    }
    
    func search(for q: String, completion: @escaping (_ data: Gist?, _ error: GistServiceError?) -> Void) {
        load { gists, error  in
            guard let gists = gists else {
                completion(nil, error)
                return
            }
            for gist in gists {
                for (filename, _) in gist.files {
                    if filename == q {
                        completion(gist, nil)
                        return
                    }
                }
                if gist.description == q {
                    completion(gist, nil)
                    return
                }
            }
            completion(nil, .failedSearch)
        }
    }
    
    func cancelLastOperation() {
        operations.last?.cancel()
    }
    
}
