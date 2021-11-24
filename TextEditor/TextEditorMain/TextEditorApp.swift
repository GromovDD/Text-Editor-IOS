//
//  TextEditorApp.swift
//  TextEditor
//
//  Created by Serega on 16.10.2021.
//

import SwiftUI
@main
struct TextEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()){ file in
            ContentView(fileURL: file.fileURL, document: file.$document)
        }
    }
}
