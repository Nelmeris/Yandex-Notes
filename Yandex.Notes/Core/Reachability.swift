//
//  Reachability.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 19/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

public class Reachability {
    
    class func isConnectedToNetwork(completion: @escaping (Bool) -> ()) {
        
        let url = URL(string: "https://google.com/")
        var request = URLRequest(url: url!)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 {
                completion(true)
            } else {
                if let error = error {
                    print(error.localizedDescription)
                }
                completion(false)
            }
        }.resume()
    }
    
}
