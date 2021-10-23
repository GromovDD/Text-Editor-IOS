//
//  ContentView.swift
//  TextNotebook
//
//  Created by Serega on 16.10.2021.
//
import HighlightedTextEditor
import SwiftUI
struct ContentView: View {
    @State private var currentSearchingWordIndex = 0
    @State private var isEditing = false
    @State private var foundedWordsCount = 0
    @State private var wordsCount = 0
    @State private var words : [String] = []
    @State private var searchText = ""
    @FocusState private var focus : Bool?
    @Binding var document: TextDocument
    func dissmisKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    func dissmisSearch()
    {
        dissmisKeyboard()
        isEditing = false
        searchText = ""
    }
    func getSubStringInString(str: String, substr: String) -> Int {
        return str.components(separatedBy: substr).count - 1
    }
    func updateFoundedWordsCount()
    {
        foundedWordsCount = getSubStringInString(str: document.text, substr: searchText)
    }
    func updateWords() {
        let components = $document.text.wrappedValue.components(separatedBy: .whitespacesAndNewlines)
        words = components.filter { !$0.isEmpty }
    }
    var body: some View {
        VStack
        {
            HStack {
                TextField("Search(beta) ...", text: $searchText)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        self.isEditing = true
                        updateFoundedWordsCount()
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
                if isEditing {
                    Button(action: {
                        dissmisSearch()
                    }) {
                        Text("Cancel")
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
                    .animation(.default)
                }
            }
            HighlightedTextEditor(text: $document.text, highlightRules: searchText.isEmpty ? []:  [HighlightRule(pattern:  try!  NSRegularExpression(pattern: searchText, options: []), formattingRule: TextFormattingRule(key: .foregroundColor, value: UIColor.red))]).focused($focus, equals: true).onTapGesture{
                dissmisKeyboard() }.onChange(of: $document.text.wrappedValue
                                             , perform: { _ in updateWords()
                    wordsCount = words.count
                    if(isEditing)
                    {
                        updateFoundedWordsCount()
                    }
                }
                )
        }.toolbar{
            ToolbarItem(placement: .bottomBar) {
                if(isEditing && foundedWordsCount > 0)
                {
                    HStack
                    {
                        Spacer()
                        Text("Founded \(foundedWordsCount)\(foundedWordsCount == 1 ? " repeat" : " repeats")")
                        Spacer()
                    }
                }
                else if (wordsCount > 0) {
                    Text("Words count: " + String(wordsCount))
                }
            }
        }.onAppear{
            if(document.text == "") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.focus = true
                }
            } else{
                updateWords()
                wordsCount = words.count
            }
        }
    }
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(document: .constant(TextDocument()))
        }
    }
    
    
}

