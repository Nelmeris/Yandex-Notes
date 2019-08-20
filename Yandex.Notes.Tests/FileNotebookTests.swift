//
//  FileNotebookTests.swift
//  NoteTests
//
//  Created by Roman Brovko on 6/19/19.
//  Copyright © 2019 Roman Brovko. All rights reserved.
//

import XCTest
@testable import Notes

class FileNotebookTests: XCTestCase {
    
    var sut: FileNotebook!
    
    override func setUp() {
        super.setUp()
        FileNotebook.removeFile()
        sut = FileNotebook()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testFileNotebook_isClass() {
        guard let fn = sut, let displayStyle = Mirror(reflecting: fn).displayStyle else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(displayStyle, .class)
    }
    
    func testFileNotebook_whenInitialized_notesIsEmpty() {
        XCTAssertTrue(sut.notes.isEmpty)
    }
    
    func testFileNotebook_whenAddNote_noteSavedInNotes() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        
        let notes = sut.notes
        
        XCTAssertEqual(notes.count, 1)
        
        let checkedNote = getNote(by: note.uid, from: notes)
        
        XCTAssertNotNil(checkedNote)
    }
    
    func testFileNotebook_whenAddNote_noteSavedInNotesWithAllInfo() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        
        guard let checkedNote = getNote(by: note.uid, from: sut.notes) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(note.uid, checkedNote.uid)
        XCTAssertEqual(note.title, checkedNote.title)
        XCTAssertEqual(note.content, checkedNote.content)
        XCTAssertEqual(note.importance, checkedNote.importance)
        XCTAssertEqual(note.color, checkedNote.color)
        
        XCTAssertNil(note.selfDestructionDate)
        XCTAssertNil(checkedNote.selfDestructionDate)
    }
    
    func testFileNotebook_whenAddNoteWithChangedInfo_updateNoteInNotes() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        
        let note2 = Note(uid: note.uid, title: "New Title", content: "My new text", color: .red, importance: .critical, destructionDate: Date())
        sut.update(note2)
        
        guard let checkedNote = getNote(by: note2.uid, from: sut.notes) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(note2.uid, checkedNote.uid)
        XCTAssertEqual(note2.title, checkedNote.title)
        XCTAssertEqual(note2.content, checkedNote.content)
        XCTAssertEqual(note2.importance, checkedNote.importance)
        XCTAssertEqual(note2.color, checkedNote.color)
        
        XCTAssertNotNil(checkedNote.selfDestructionDate)
        
        guard let checkedDate = checkedNote.selfDestructionDate, let date = note2.selfDestructionDate else {
            return
        }
        
        XCTAssertEqual(checkedDate, date)
    }
    
    
    func testFileNotebook_whenDeleteNote_noteRemoveFromNotes() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        sut.remove(with: note.uid)
        
        let notes = sut.notes
        
        XCTAssertTrue(notes.isEmpty)
    }
    
    func testFileNotebook_whenSaveToFileAndLoadFromFile_correctRestoreNotes() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        
        let note2 = Note(title: "New Title", content: "My new text", color: .red, importance: .usual, destructionDate: Date())
        sut.add(note2)
        
        sut.saveToFile()
        
        sut.remove(with: note.uid)
        sut.remove(with: note2.uid)
        
        XCTAssertTrue(sut.notes.isEmpty)
        
        let note3 = Note(title: "New Title3", content: "My new text3", color: .green, importance: .insignificant, destructionDate: Date())
        sut.add(note3)
        
        sut.loadFromFile()
        
        let notes = sut.notes
        XCTAssertEqual(notes.count, 2)
        XCTAssertNotNil(getNote(by: note.uid, from: notes))
        XCTAssertNotNil(getNote(by: note2.uid, from: notes))
    }
    
    func testFileNotebook_whenSaveToFileAndLoadFromFile_equalsRestoredNotes() {
        let note = Note(title: "Title", content: "Text", importance: .usual)
        sut.add(note)
        
        let note2 = Note(title: "New Title", content: "My new text", color: .red, importance: .critical, destructionDate: Date())
        sut.add(note2)
        
        sut.saveToFile()
        
        sut.loadFromFile()
        
        let notes = sut.notes
        
        guard let checkedNote = getNote(by: note.uid, from: notes),
            let checkedNote2 = getNote(by: note2.uid, from: notes) else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(note.uid, checkedNote.uid)
        XCTAssertEqual(note.title, checkedNote.title)
        XCTAssertEqual(note.content, checkedNote.content)
        XCTAssertEqual(note.importance, checkedNote.importance)
        XCTAssertEqual(note.color, checkedNote.color)
        
        XCTAssertNil(checkedNote.selfDestructionDate)
        
        guard let checkedDate = checkedNote.selfDestructionDate, let date = note.selfDestructionDate else {
            return
        }
        
        XCTAssertEqual(checkedDate, date)
        
        
        XCTAssertEqual(note2.uid, checkedNote2.uid)
        XCTAssertEqual(note2.title, checkedNote2.title)
        XCTAssertEqual(note2.content, checkedNote2.content)
        XCTAssertEqual(note2.importance, checkedNote2.importance)
        XCTAssertEqual(note2.color, checkedNote2.color)
        
        XCTAssertNotNil(checkedNote.selfDestructionDate)
        
        guard let checkedDate2 = checkedNote2.selfDestructionDate, let date2 = note2.selfDestructionDate else {
            return
        }
        
        XCTAssertEqual(checkedDate2, date2)
        
    }
    
    
    private func getNote(by uid: String, from notes:Any) -> Note? {
        if let notes = notes as? [String: Note] {
            return notes[uid]
        }
        
        if let notes = notes as? [Note] {
            return notes.filter { $0.uid == uid }.first
        }
        
        return nil
    }
}
