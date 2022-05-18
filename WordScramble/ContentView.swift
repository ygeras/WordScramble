//
//  ContentView.swift
//  WordScramble
//
//  Created by Yuri Gerasimchuk on 16.05.2022.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
    
    var body: some View {
        NavigationView {
            List {
                Section {
                        HStack {
                        Spacer()
                        Text("Your score is \(score)")
                        Spacer()
                    }
                }
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never)
                }
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                Button("Start Game") {
                    startGame()
                }
            }

        }
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // exit if the answer contains less than 3 letters or answer is the same as the rootWord
        guard answer.count > 3 && answer != rootWord else {
            wordError(title: "Word cannot be used", message: "Word must contain at least 4 letters and differ from root word.")
            return
            
        }
                
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from \(rootWord)!")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        // score: if derived word is 8 letters you score 5 points, if the word contains between 6 and up to 8 letters you score 2 points, all other cases you score just 1 point
        switch answer.count {
        case 8:
            score += 5
        case 6 ..< 8:
            score += 2
        default:
            score += 1
        }
        
        // bonus points: if you manage to make 3 derived words from root word you score 2 bonus points for each additional word onwards, if you make 5 and more words you score 5 points for each additional word onwards.
        switch usedWords.count {
        case 0 ..< 3:
            score += 0
        case 3 ..< 5:
            score += 2
        default:
            score += 5
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    
    func startGame() {
        // find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                // pick one randow word, or use "silkworm as a sensible default
                rootWord = allWords.randomElement() ?? "silkworm"
                // clear any used words in the usedWords array if any
                usedWords.removeAll()
                // clear score
                score = 0
                // if we're here everything has worked, so we can exit
                return
            }
        }
        // if we're *here* then there was a problem - trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
