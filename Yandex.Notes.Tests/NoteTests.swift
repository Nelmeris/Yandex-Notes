//
//  NoteTests.swift
//  NoteTests
//
//  Created by Roman Brovko on 6/17/19.
//  Copyright © 2019 Roman Brovko. All rights reserved.
//

import XCTest
@testable import Yandex_Notes

class NoteTests: XCTestCase {
    
    private let uuid = UUID()
    private let title = "title"
    private let content = "text"
    private let importance = NoteImportanceLevel.usual
    private var sut: Note!
    
    override func setUp() {
        super.setUp()
        sut = Note(title: title, content: content, importance: importance)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testNote_isStruct() {
        guard let note = sut, let displayStyle = Mirror(reflecting: note).displayStyle else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(displayStyle, .struct)
    }
    
    func testNote_whenInitialized_isSetUUID() {
        let note = Note(uuid: uuid, title: title, content: content, importance: importance)
        
        XCTAssertEqual(uuid, note.uuid)
    }
    
    func testNote_whenInitialized_isSetDefaultUUID() {
        let note = Note(title: title, content: content, importance: importance)
        
        XCTAssertNotEqual(sut.uuid, note.uuid)
    }
    
    func testNote_whenInitialized_setTitle() {
        XCTAssertEqual(sut.title, title)
    }
    
    func testNote_whenInitialized_setContent() {
        XCTAssertEqual(sut.content, content)
    }
    
    func testNote_whenInitialized_setImportance() {
        XCTAssertEqual(sut.importance, importance)
    }
    
    
    func testNote_whenInitialized_defaultColor() {
        XCTAssertEqual(sut.color, .white)
    }
    
    func testNote_whenInitialized_customColor() {
        let color = UIColor.red
        let note = Note(title: title, content: content, color: color, importance: importance)
        
        XCTAssertEqual(note.color, color)
    }
    
    func testNote_whenInitialized_defaultDate() {
        XCTAssertNil(sut.destructionDate)
    }
    
    func testNote_whenInitialized_customDate() {
        let date = Date()
        let note = Note(title: title, content: content, importance: .critical, destructionDate: date)
        
        XCTAssertEqual(date, note.destructionDate)
    }
    
}
