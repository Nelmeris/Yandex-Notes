//
//  PullNotesGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 23/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum PullNotesGistOperationResult {
    case success(GistNotesContainer)
    case failure
    case failureRequest(NetworkError)
}

class PullNotesGistOperation: BaseGistForNotesOperation {
    
    private var getGistForNotes: GetGistForNotesOperation?
    private var createGistForNotes: CreateGistOperation?
    
    private(set) var result: PullNotesGistOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    override init(title: String? = nil, id: Int? = nil) {
        super.init(title: title ?? "Pull notes from gist", id: id)
        
        getGistForNotes = GetGistForNotesOperation(id: self.id?.number)
        
        let getGistForNotesCompletion = BlockOperation {
            guard let result = self.getGistForNotes?.result else { return }
            self.getGistForNotesCompletion(with: result)
        }
        
        getGistForNotesCompletion.addDependency(getGistForNotes!)
        commonQueue.addOperation(getGistForNotesCompletion)
        addDependency(getGistForNotesCompletion)
        queue.addOperation(getGistForNotes!)
    }
    
    private func getGistForNotesCompletion(with result: GetGistForNotesOperationResult) {
        switch self.getGistForNotes!.result! {
        case .failure:
            let gistCreator = createGistCreator()
            let createGistForNotes = CreateGistOperation(gistCreator: gistCreator)
            self.createGistForNotes = createGistForNotes
            queue.addOperation(createGistForNotes)
            addDependency(createGistForNotes)
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        default: break
        }
    }
    
    private func createGistForNotesCompletion(with result: CreateGistOperationResult) {
        switch self.createGistForNotes!.result! {
        case .success(let gist):
            do {
                guard let gistContainer = try parseNotes(from: gist) else {
                    self.result = .failure
                    return
                }
                self.result = .success(gistContainer)
            } catch {
                self.result = .failure
            }
        case .failure:
            self.result = .failure
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    override func main() {
        guard let result = getGistForNotes?.result else { return }
        switch result {
        case .success(let gist):
            do {
                guard let gistContainer = try parseNotes(from: gist) else {
                    self.result = .failure
                    return
                }
                self.result = .success(gistContainer)
            } catch {
                self.result = .failure
            }
        default:
            if let createGistForNotesResult = createGistForNotes?.result {
                createGistForNotesCompletion(with: createGistForNotesResult)
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        getGistForNotes?.cancel()
        createGistForNotes?.cancel()
    }
    
}
