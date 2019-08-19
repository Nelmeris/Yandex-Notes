//
//  AsyncOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    
    private var _executing = false 
    private var _finished = false
    private let title: String
    static var count = 0
    private let number: Int
    
    init(title: String) {
        self.title = title
        let lock = NSLock()
        lock.lock()
        AsyncOperation.count += 1
        self.number = AsyncOperation.count
        lock.unlock()
        super.init()
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    override var isFinished: Bool {
        return _finished
    }
    
    override func start() {
        guard !isCancelled else {
            finish()
            return
        }
        willChangeValue(forKey: "isExecuting")
        print("\(number): \(title) operation started")
        _executing = true
        didChangeValue(forKey: "isExecuting")
        main()
    }
    
    override func main() {
        fatalError("Should be overriden")
    }
    
    func finish() {
        willChangeValue(forKey: "isFinished")
        print("\(number): \(title) operation finished")
        _finished = true
        didChangeValue(forKey: "isFinished")
    }
    
}
