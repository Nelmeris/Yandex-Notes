//
//  PushNotesGistOperation.swift
//  Yandex.Notes
//
//  Created by Артем Куфаев on 23/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

enum PushNotesGistOperationResult {
    case success
    case failure
    case failureRequest(NetworkError)
}

class PushNotesGistOperation: BaseGistForNotesOperation {
    
    private var getGistForNotes: GetGistForNotesOperation?
    private var createGistForNotes: CreateGistOperation?
    private var patchGistForNotes: PatchGistOperation?
    
    private let notes: [Note]
    
    private(set) var result: PushNotesGistOperationResult? {
        didSet {
            guard !isCancelled else { return }
            finish()
        }
    }
    
    init(notes: [Note], title: String? = nil, id: Int? = nil) {
        self.notes = notes
        
        super.init(title: title ?? "Push notes to gist", id: id)
        
        getGistForNotes = GetGistForNotesOperation(id: self.id?.number)
        
        let getGistForNotesCompletion = BlockOperation {
            guard let result = self.getGistForNotes!.result else { return }
            self.getGistForNotesCompletion(with: result)
        }
        
        getGistForNotesCompletion.addDependency(getGistForNotes!)
        commonQueue.addOperation(getGistForNotesCompletion)
        queue.addOperation(getGistForNotes!)
        addDependency(getGistForNotesCompletion)
    }
    
    private func getGistForNotesCompletion(with result: GetGistForNotesOperationResult) {
        let gistCreator = self.createGistCreator(with: self.notes)
        switch self.getGistForNotes!.result! {
        case .success(let gist):
            let patchGistForNotes = PatchGistOperation(gistCreator: gistCreator, gistId: gist.id, id: self.id?.number)
            self.patchGistForNotes = patchGistForNotes
            queue.addOperation(patchGistForNotes)
            addDependency(patchGistForNotes)
        case .failure:
            let createGistForNotes = CreateGistOperation(gistCreator: gistCreator, id: self.id?.number)
            self.createGistForNotes = createGistForNotes
            queue.addOperation(createGistForNotes)
            addDependency(createGistForNotes)
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    private func createGistForNotesCompletion(with result: CreateGistOperationResult) {
        switch self.createGistForNotes!.result! {
        case .success(_):
            self.result = .success
        case .failure:
            self.result = .failure
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    private func patchGistForNotesCompletion(with result: PatchGistOperationResult) {
        switch self.patchGistForNotes!.result! {
        case .success(_):
            self.result = .success
        case .failure:
            self.result = .failure
        case .failureRequest(let error):
            self.result = .failureRequest(error)
        }
    }
    
    override func main() {
        if let createGistForNotesResult = createGistForNotes?.result {
            createGistForNotesCompletion(with: createGistForNotesResult)
        } else if let patchGistForNotesResult = patchGistForNotes?.result {
            patchGistForNotesCompletion(with: patchGistForNotesResult)
        }
    }
    
    override func cancel() {
        super.cancel()
        getGistForNotes?.cancel()
        patchGistForNotes?.cancel()
        createGistForNotes?.cancel()
    }
    
}
