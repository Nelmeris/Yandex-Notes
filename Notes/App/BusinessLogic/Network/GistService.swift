//
//  GistService.swift
//  Notes
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
    
    private func executeRequest(with method: RequestMethods, path: String, data: Data? = nil, completion: @escaping (Data?) -> Void) {
        let operation = ExecuteGistRequestOperation(method: method, path: path, data: data)
        operation.completionBlock = {
            guard let result = operation.result else { fatalError() }
            switch result {
            case .success(let data, statusCode: let code):
                print("Network request success. Status code: \(code)")
                completion(data)
            case .failture(let error):
                switch error {
                case .failedRequest(let error):
                    print("Network request error. \(error)")
                case .failedResponse(let error):
                    print("Network response error. \(error.localizedDescription)")
                }
                completion(nil)
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
            executeRequest(with: .post, path: "gists", data: data) { data in
                guard let data = data else {
                    completion(nil, .failedCreation)
                    return
                }
                do {
                    let newGist = try JSONDecoder().decode(Gist.self, from: data)
                    completion(newGist, nil)
                } catch {
                    completion(nil, .failedDecodeData(error))
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
            executeRequest(with: .patch, path: "gists/\(gistId)", data: data) { data in
                guard data != nil else {
                    completion(.failedPatch)
                    return
                }
                completion(nil)
            }
        } catch {
            completion(.failedEncodeData(error))
        }
    }
    
    // Загрузить все Gist's пользователя
    func load(completion: @escaping (_ data: [Gist]?, _ error: GistServiceError?) -> Void) {
        executeRequest(with: .get, path: "gists") { data in
            guard let data = data else {
                completion(nil, .failedLoad)
                return
            }
            do {
                let gists = try JSONDecoder().decode([Gist].self, from: data)
                completion(gists, nil)
            } catch {
                completion(nil, .failedDecodeData(error))
            }
        }
    }
    
    // Получить определенный Gist по ID
    func get(with gistId: String, completion: @escaping (_ data: Gist?, _ error: GistServiceError?) -> Void) {
        executeRequest(with: .get, path: "gists/\(gistId)") { data in
            guard let data = data else {
                completion(nil, .failedGet)
                return
            }
            do {
                let gist = try JSONDecoder().decode(Gist.self, from: data)
                completion(gist, nil)
            } catch let error {
                completion(nil, .failedDecodeData(error))
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
    
}
