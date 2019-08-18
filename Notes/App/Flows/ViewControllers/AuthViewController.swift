//
//  AuthViewController.swift
//  Gists
//
//  Created by Artem Kufaev on 12.08.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import WebKit

protocol AuthViewControllerDelegate: class {
    func handleTokenChanged(token: String)
}

class AuthViewController: UIViewController {
    
    weak var delegate: AuthViewControllerDelegate?
    
    var webView: WKWebView!
    let clientId = "fa1e2e46ae34759496dd"
    let clientSecret = "3ac56ba0ac4292d035e1a34a428e8bef96b12c16"
    private let gitHubDomain = "https://github.com/"
    
    private var request: URLRequest? {
        guard var urlComponents = URLComponents(string: "https://github.com/login/oauth/authorize") else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: "gist")
        ]
        guard let url = urlComponents.url else { return nil }
        return URLRequest(url: url)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureWebView()
        loadWebContent()
    }
    
    private func configureWebView() {
        webView = WKWebView(frame: self.view.bounds)
        view.addSubview(webView)
    }
    
    private func loadWebContent() {
        guard let request = request else { return }
        webView?.load(request)
        webView.navigationDelegate = self
    }

}

extension AuthViewController {
    
    func getTokenRequest(with code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://github.com/login/oauth/access_token") else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: code)
        ]
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return request
    }
    
    func requestToken(with code: String) {
        guard let request = getTokenRequest(with: code) else { return }
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            guard error == nil,
                let data = data else {
                    print(error.debugDescription)
                    return
            }
            
            guard let responseString = String(data: data, encoding: .utf8) else { return }
            guard let components = URLComponents(string: "\(strongSelf.gitHubDomain)?\(responseString)") else { return }
            
            if let token = components.queryItems?.first(where: { $0.name == "access_token" })?.value {
                UserDefaults.standard.set(token, forKey: GistService.shared.accessTokenKey)
                strongSelf.dismiss(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: GistService.shared.notificationKey), object: token)
                strongSelf.delegate?.handleTokenChanged(token: token)
            }
        }.resume()
    }
    
}

extension AuthViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let targetString = url.absoluteString.replacingOccurrences(of: "#", with: "?")
        guard let components = URLComponents(string: targetString) else {
            decisionHandler(.allow)
            return
        }
        
        if let code = components.queryItems?.first(where: { $0.name == "code"})?.value {
            decisionHandler(.cancel)
            requestToken(with: code)
            return
        }
        
        decisionHandler(.allow)
        
    }
    
}
