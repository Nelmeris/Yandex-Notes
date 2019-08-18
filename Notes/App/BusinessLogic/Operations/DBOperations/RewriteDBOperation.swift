//
//  RewriteDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 13/08/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class RewriteDBOperation: BaseDBOperation {
    
    private let notes: [Note]
    
    init(notes: [Note],
         notebook: FileNotebook) {
        self.notes = notes
        super.init(title: "Rewrite DataBase", notebook: notebook)
    }
    
    override func main() {
        notebook.removeAll()
        notebook.add(notes)
        finish()
    }
    
}
