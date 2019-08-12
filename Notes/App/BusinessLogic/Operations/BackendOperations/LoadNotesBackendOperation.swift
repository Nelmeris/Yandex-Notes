//
//  LoadNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum LoadNotesBackendResult {
    case success([Note])
    case failure(NetworkError)
}

class LoadNotesBackendOperation: BaseBackendOperation {
    private(set) var result: LoadNotesBackendResult?
    
    private func failture() {
        self.result = .failure(.unreachable)
        self.finish()
    }
    
    override func main() {
        guard let url = URL(string: gitHubAPIURL + "gists/\(gistId)") else { failture(); return }
        var gistRequest = URLRequest(url: url)
        gistRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: gistRequest) {
            [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200..<300:
                    if let data = data {
                        do {
                            let gist = try JSONDecoder().decode(Gist.self, from: data)
                            let gistFileContent = gist.files[strongSelf.jsonGistFileName]!.content
                            let data = gistFileContent?.data(using: .utf8)
                            let notes = try JSONDecoder().decode([Note].self, from: data!)
                            strongSelf.result = .success(notes)
                        } catch let error {
                            print(error)
                            strongSelf.result = .failure(.unreachable)
                        }
                    } else {
                        strongSelf.result = .failure(.unreachable)
                    }
                default:
                    strongSelf.result = .failure(.unreachable)
                }
            }
        }
        task.resume()
    }
}
