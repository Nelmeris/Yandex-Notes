//
//  SaveNotesBackendOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum SaveNotesBackendResult {
    case success
    case failure(NetworkError)
}

class SaveNotesBackendOperation: BaseBackendOperation {
    private(set) var result: SaveNotesBackendResult?
    private var notes: [Note]?
    
    init(notes: [Note]) {
        self.notes = notes
        super.init()
    }
    
    private func failture() {
        self.result = .failure(.unreachable)
        self.finish()
    }
    
    override func main() {
        guard
            let url = URL(string: gitHubAPIURL + "gists/\(gistId)"),
            let gistContent = try? JSONEncoder().encode(notes),
            let gistContentString = String(data: gistContent, encoding: .utf8) else {
                failture()
                return
        }
        let gistFile = GistFileCreator(content: gistContentString, filename: jsonGistFileName)
        let gist = GistCreator(public: false, description: "Yandex.Notes for Stepic", files: [jsonGistFileName: gistFile])
        
        guard let gistJson = try? JSONEncoder().encode(gist) else {
            failture()
            return
        }
        
        var gistRequest = URLRequest(url: url)
        gistRequest.httpMethod = "PATCH"
        gistRequest.httpBody = gistJson
        gistRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: gistRequest) {
            [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200..<300:
                    strongSelf.result = .success
                default:
                    strongSelf.result = .failure(.unreachable)
                }
            }
            strongSelf.finish()
        }
        task.resume()
    }
}
