//
//  LoadNotesDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class LoadNotesDBOperation: BaseDBOperation {
    
    private(set) var result: [Note]? {
        didSet {
            finish()
        }
    }
    
    init(notebook: FileNotebook) {
        super.init(title: "Load notes from DataBase", notebook: notebook)
    }
    
    override func main() {
        self.result = self.notebook.notes
    }
    
}
