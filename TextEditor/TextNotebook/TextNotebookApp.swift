//
//  TextNotebookApp.swift
//  TextNotebook
//
//  Created by Serega on 16.10.2021.
//

import SwiftUI
@main
struct TextNotebookApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
