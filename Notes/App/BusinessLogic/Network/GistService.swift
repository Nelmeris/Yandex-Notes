//
//  GistService.swift
//  Notes
//
//  Created by Артем Куфаев on 12.08.2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import Foundation

class GistService {
    
    private init() {}
    static let shared = GistService()
    
    let gitHubAPIURL = "https://api.github.com"
    
    private let accessTokenKey = "access_token"
    
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
    
    enum RequestErrors: Error, LocalizedError {
        case invalidUrlPath
        
        var localizedDescription: String {
            switch self {
            case .invalidUrlPath:
                return "Invalid path to API method"
            }
        }
    }
    
    enum RequestMethods: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
    }
    
    private func createRequest(with method: RequestMethods, path: String, httpBody: Data? = nil) throws -> URLRequest {
        guard let token = accessToken,
            let url = URL(string: "\(gitHubAPIURL)/\(path)") else { throw RequestErrors.invalidUrlPath }
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = method.rawValue
        request.httpBody = httpBody
        return request
    }
    
    let dispatchGroup = DispatchGroup()
    
    private func executeRequest(with method: RequestMethods, path: String, data: Data? = nil, completion: @escaping (Data?) -> Void) throws {
        let request = try createRequest(with: method, path: path, httpBody: data)
        dispatchGroup.wait()
        dispatchGroup.enter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        print("\(dateFormatter.string(from: Date())): Request \(method.rawValue)/\(request.url!.absoluteString)")
        URLSession.shared.dataTask(with: request) { result in
            self.dispatchGroup.leave()
            switch result {
            case .success(let result):
                print("\(dateFormatter.string(from: Date())): Network. Success request. Status code: \(result.statusCode)")
                completion(result.data)
            case .redirection(let result):
                print("\(dateFormatter.string(from: Date())): Network. Redirection error. Status code: \(result.statusCode). Description: \(result.error.localizedDescription)")
                completion(nil)
            case .clientError(let result):
                print("\(dateFormatter.string(from: Date())): Network. Client error. Status code: \(result.statusCode). Description: \(result.error.localizedDescription)")
                completion(nil)
            case .serverError(let result):
                print("\(dateFormatter.string(from: Date())): Network. Server error. Status code: \(result.statusCode). Description: \(result.error.localizedDescription)")
                completion(nil)
            case .unknownError(let error):
                print("\(dateFormatter.string(from: Date())): Network. Unknown error. Description: \(error.localizedDescription)")
                completion(nil)
            case .unexpectedError(_):
                print("\(dateFormatter.string(from: Date())): Network. Unexpected error")
                completion(nil)
            }
        }.resume()
    }
    
    // Создать новый Gist
    func create(with gist: GistCreator, completion: @escaping (Gist?) -> Void) {
        do {
            let data = try JSONEncoder().encode(gist)
            try executeRequest(with: .post, path: "gists", data: data) { data in
                guard let data = data else {
                    completion(nil)
                    return
                }
                do {
                    let newGist = try JSONDecoder().decode(Gist.self, from: data)
                    completion(newGist)
                } catch {
                    print(error.localizedDescription)
                    completion(nil)
                }
            }
        } catch {
            print("Network. Request error. Description: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Обновить Gist по ID
    func patch(with gistId: String, gist: GistCreator, completion: @escaping (Bool) -> Void) {
        do {
            let data = try JSONEncoder().encode(gist)
            try executeRequest(with: .patch, path: "gists/\(gistId)", data: data) { data in
                guard data != nil else {
                    completion(false)
                    return
                }
            }
            completion(true)
        } catch {
            print("Network. Request error. Description: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Загрузить все Gist's пользователя
    func load(completion: @escaping ([Gist]?) -> Void) {
        do {
            try executeRequest(with: .get, path: "gists") { data in
                guard let data = data else {
                    completion(nil)
                    return
                }
                do {
                    let gists = try JSONDecoder().decode([Gist].self, from: data)
                    completion(gists)
                } catch {
                    print(error.localizedDescription)
                    completion(nil)
                }
            }
        } catch {
            print("Network. Request error. Description: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Получить определенный Gist по ID
    func get(with gistId: String, completion: @escaping (Gist?) -> Void) {
        do {
            try executeRequest(with: .get, path: "gists/\(gistId)") { data in
                guard let data = data else {
                    completion(nil)
                    return
                }
                do {
                    let gist = try JSONDecoder().decode(Gist.self, from: data)
                    completion(gist)
                } catch {
                    print(error.localizedDescription)
                    completion(nil)
                }
            }
        } catch {
            print("Network. Request error. Description: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func search(for q: String, completion: @escaping (_ gist: Gist?) -> Void) {
        load { gists in
            guard let gists = gists else {
                completion(nil)
                return
            }
            for gist in gists {
                for (filename, _) in gist.files {
                    if filename == q {
                        completion(gist)
                        return
                    }
                }
                if gist.description == q {
                    completion(gist)
                    return
                }
            }
            completion(nil)
        }
    }
    
}
