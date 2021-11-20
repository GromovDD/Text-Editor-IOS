//
//  ContentView.swift
//  TextNotebook
//
//  Created by Serega on 16.10.2021.
//
import SPAlert
import HighlightedTextEditor
import SwiftUI
import UIKit
extension String {
    func caseInsensitiveSplit(separator: String) -> [String] {
        if separator.isEmpty {
            return [self]
        }
        let pattern = NSRegularExpression.escapedPattern(for: separator)
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: self, options: [], range: NSRange(0..<self.utf16.count))
        let ranges = (0..<matches.count+1).map { (i: Int)->NSRange in
            let start = i == 0 ? 0 : matches[i-1].range.location + matches[i-1].range.length
            let end = i == matches.count ? self.utf16.count: matches[i].range.location
            return NSRange(location: start, length: end-start)
        }
        return ranges.map {String(self[Range($0, in: self)!])}
    }
}
struct ContentView: View {
    private let urlRegex = HighlightRule(pattern: try! NSRegularExpression(pattern: "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?", options: []), formattingRules: [
        TextFormattingRule(key: .underlineStyle, value: NSUnderlineStyle.single.rawValue),
        TextFormattingRule(key: .link) { urlString, _ in
            URL(string: urlString) as Any
        }
    ])
    @State private var copyCompleted  = false
    @State private var saveAvailable = true
    private let alertDuration = 0.5
    @State private var showSaveSuccessAlert = false
    @State public var fileURL: URL?
    @State private var showSaveErrorAlert = false
    @State private var empty = NSObject()
    @Environment(\.undoManager) var undoManager
    @State private var oldText = ""
    @State private var choosedColor = Color.red
    @State private var currentHighlightColor = UIColor.red
    @State private var showColorChooseView = false
    @State private var isSearching = false
    @State private var foundedWordsCount = 0
    @State private var wordsCount = 0
    @State private var searchText = ""
    @FocusState private var searchBarFocus : Bool
    @FocusState private var editorFocus : Bool
    @Binding public var document: TextDocument
    private func getBottomText() -> String
    {
        var result = ""
        if(isSearching && foundedWordsCount > 0)
        {
            result = "Founded \(foundedWordsCount)\(foundedWordsCount == 1 ? " repeat" : " repeats")"
        }
        else {
            result = "Words count: \(wordsCount)"
        }
        return result
    }
    private func dissmisKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    private func saveColor()
    {
        UserDefaults.standard.highlightColor = currentHighlightColor
    }
    private func dissmisSearch()
    {
        dissmisKeyboard()
        searchText = ""
        withAnimation(.default) {
            isSearching = false
        }
    }
    private func getSubStringInString(str: String, substr: String) -> Int {
        return str.caseInsensitiveSplit(separator: substr).count - 1
    }
    private func updateFoundedWordsCount()
    {
        foundedWordsCount = getSubStringInString(str: document.text, substr: searchText)
    }
    private func updateWordsCount() {
        let components = $document.text.wrappedValue.components(separatedBy: .whitespacesAndNewlines)
        wordsCount = components.filter { !$0.isEmpty }.count
    }
    private func getHighlightRules(pattern: String) -> [HighlightRule]
    {
        do{
            let regularExpression = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .ignoreMetacharacters])
            return [HighlightRule(pattern: regularExpression, formattingRule: .init(key: .foregroundColor, value: currentHighlightColor)), urlRegex]
        } catch {
            return [urlRegex]
        }
    }
    var body: some View {
        VStack
        {
            if(isSearching) {
                HStack {
                    MultilineTextField("Search(beta)...", text: $searchText,maxHeight: 82.0).focused($searchBarFocus)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            if(searchBarFocus) {
                                dissmisKeyboard()
                            }
                        }.overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15)
                            }
                        ).onChange(of: searchText, perform: {_ in
                            updateFoundedWordsCount()
                        })
                    Button(action: {
                        dissmisSearch()
                    }) {
                        Text("Cancel")
                    }
                    .padding(.trailing, 10)
                }.transition(.move(edge: .top).combined(with: .opacity)).padding(.vertical, 5)
                
            }
            HighlightedTextEditor(text: $document.text, highlightRules: getHighlightRules(pattern: searchText.trimmingCharacters(in: .whitespacesAndNewlines))).onSelectionChange{ _ in
            }.onTextChange { text in
                undoManager?.registerUndo(withTarget: empty, handler:  { _ in
                    let oldText = text
                    document.text = oldText
                })
            }.focused($editorFocus).onTapGesture
            {
                if(editorFocus) {
                    dissmisKeyboard()
                }
            }.onChange(of: document.text, perform: {_ in
                updateWordsCount()
                if(isSearching)
                {
                    updateFoundedWordsCount()
                }
            })
        }.toolbar{
            ToolbarItem(placement: .navigationBarTrailing)
            {
                HStack {
                    Button(action:
                            {
                        do {
                            saveAvailable = false
                            try document.save().write(to: fileURL!, options: [], originalContentsURL: nil)
                            showSaveSuccessAlert = true
                        } catch {
                            showSaveErrorAlert = true
                        }
                    }
                           , label: {
                        Image(systemName: "folder").accentColor(saveAvailable ? .blue : .gray)
                    }
                    ).disabled(!saveAvailable).spAlert(isPresent: $showSaveSuccessAlert, title: "Successful saved!", message: nil, duration: alertDuration, dismissOnTap: false, preset: .done, haptic: .success, layout: nil, completion: {
                        saveAvailable = true
                    }).spAlert(isPresent: $showSaveErrorAlert, title: "Error while saving!", message: nil, duration: alertDuration, dismissOnTap: false, preset: .error, haptic: .error, layout: nil, completion: {
                        saveAvailable = true
                    })
                    ColorPicker("Select highlight color", selection: $choosedColor, supportsOpacity: false).onChange(of: choosedColor, perform: {
                        color in
                        currentHighlightColor = UIColor(color)
                        saveColor()
                    }).labelsHidden()
                    if(!isSearching) {
                        Button(action: {
                            withAnimation(.default) {
                                isSearching = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    searchBarFocus = true
                                }
                            }
                        }, label:
                                {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                }.transition(.move(edge: .trailing).combined(with: .opacity))
            }
            ToolbarItem(placement: .navigationBarLeading, content: {
                HStack
                {
                    let canUndo = undoManager?.canUndo ?? false
                    let canRedo = undoManager?.canRedo ?? false
                    Button(action: {
                        if(canUndo){
                            undoManager?.undo()
                        }
                    }, label: { Image(systemName: "arrow.left.circle").foregroundColor(canUndo ? .blue : .gray)}).disabled(!canUndo)
                    Button(action: {
                        if(canRedo){
                            undoManager?.redo()
                        }
                    }, label: { Image(systemName: "arrow.forward.circle").foregroundColor(canRedo ? .blue : .gray)}).disabled(!canRedo)
                }
                
            })
            ToolbarItem(placement: .bottomBar)
            {
                Text(getBottomText())
            }
        }.onAppear{
            if(document.text.isEmpty) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    editorFocus = true
                }
            } else{
                updateWordsCount()
            }
            currentHighlightColor = UserDefaults.standard.highlightColor ?? .red
            choosedColor = Color(currentHighlightColor)
            oldText = document.text
        }.toolbar{
            ToolbarItem(placement: .navigationBarTrailing)
            {
                HStack {
                    Button(action:
                            {
                        do {
                            saveAvailable = false
                            try document.save().write(to: fileURL!, options: [], originalContentsURL: nil)
                            showSaveSuccessAlert = true
                        } catch {
                            showSaveErrorAlert = true
                        }
                    }
                           , label: {
                        Image(systemName: "folder").accentColor(saveAvailable ? .blue : .gray)
                    }
                    ).disabled(!saveAvailable)
                    ColorPicker("Select highlight color", selection: $choosedColor, supportsOpacity: false).onChange(of: choosedColor, perform: {
                        color in
                        currentHighlightColor = UIColor(color)
                        saveColor()
                    }).labelsHidden()
                    if(!isSearching) {
                        Button(action: {
                            withAnimation(.default) {
                                isSearching = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    searchBarFocus = true
                                }
                            }
                        }, label:
                                {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                }.transition(.move(edge: .trailing).combined(with: .opacity))
            }
            ToolbarItem(placement: .navigationBarLeading, content: {
                HStack
                {
                    let canUndo = undoManager?.canUndo ?? false
                    let canRedo = undoManager?.canRedo ?? false
                    Button(action: {
                        if(canUndo){
                            undoManager?.undo()
                        }
                    }, label: { Image(systemName: "arrow.left.circle").foregroundColor(canUndo ? .blue : .gray)}).disabled(!canUndo)
                    Button(action: {
                        if(canRedo){
                            undoManager?.redo()
                        }
                    }, label: { Image(systemName: "arrow.forward.circle").foregroundColor(canRedo ? .blue : .gray)}).disabled(!canRedo)
                }
                
            })
            ToolbarItem(placement: .bottomBar)
            {
                HStack {
                    Spacer()
                    Text(getBottomText())
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = document.text
                        copyCompleted = true
                    }, label: { Image(systemName: "doc.on.doc")}).spAlert(isPresent: $copyCompleted, title: "Successful copied!", message: nil, duration: alertDuration, dismissOnTap: false, preset: .done, haptic: .success, layout: nil, completion: nil)
                }
            }
        }.onAppear{
            if(document.text.isEmpty) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    editorFocus = true
                }
            } else{
                updateWordsCount()
            }
            currentHighlightColor = UserDefaults.standard.highlightColor ?? .red
            choosedColor = Color(currentHighlightColor)
            oldText = document.text
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fileURL: nil, document: .constant(TextDocument()))
    }
}




