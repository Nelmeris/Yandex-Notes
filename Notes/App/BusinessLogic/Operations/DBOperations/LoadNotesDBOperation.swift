//
//  LoadNotesDBOperation.swift
//  Notes
//
//  Created by Artem Kufaev on 25.07.2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import Foundation

class LoadNotesDBOperation: BaseDBOperation {
    private(set) var result: [Note]?
    
    override func main() {
        print("Start load from DataBase operation")
        self.result = self.notebook.notes
        self.finish()
    }
}
