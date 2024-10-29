//
//  ContentView.swift
//  Introlink
//
//  Created by Lakshya . music on 8/29/24.
//
import SwiftUI
import SwiftData

struct User: Identifiable {
    let id = UUID()
    var name: String
    var age: Int
    var school: String
    var gender: String
    var interests: [String]
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromMatch: Bool
}

class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var matches: [User] = []
    @Published var selectedMatch: User?
    @Published var messages: [Message] = []

    func saveUser(name: String, age: Int, school: String, gender: String, interests: [String]) {
        currentUser = User(name: name, age: age, school: school, gender: gender, interests: interests)
    }

    func findMatches() {
        guard let currentUser = currentUser else { return }
        
        let dummyUsers = [
            User(name: "Christina", age: 18, school: "Plaksha University", gender: "Female", interests: ["Music", "Tennis"]),
            User(name: "ANdy", age: 18, school: "Harvard", gender: "Male", interests: ["Football", "Singing"]),
            User(name: "Charlie", age: 18, school: "Stanford", gender: "Other", interests: ["Piano", "Soccer"])
        ]
        
        matches = dummyUsers.filter { user in
            !Set(user.interests).isDisjoint(with: Set(currentUser.interests))
        }
    }

    func selectMatch(_ match: User) {
        selectedMatch = match
        messages = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addMessage("Hi there! I see we both enjoy \(match.interests.first ?? "interesting things"). How's your day going?", isFromMatch: true)
        }
    }

    func addMessage(_ content: String, isFromMatch: Bool) {
        let newMessage = Message(content: content, isFromMatch: isFromMatch)
        messages.append(newMessage)
    }
}

struct ContentView: View {
    @StateObject private var userManager = UserManager()
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var userAge = ""
    @State private var userSchool = ""
    @State private var userGender = ""
    @State private var selectedInterests: Set<String> = []

    let steps = ["Getting Started", "Basic Info", "Interests", "Your Match", "Message"]
    let allInterests = ["Music", "Dance", "Singing", "Research", "Football", "Tennis", "Soccer", "Piano", "Guitar"]

    var body: some View {
        NavigationView {
            VStack {
                ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                    .padding()

                TabView(selection: $currentStep) {
                    WelcomeView()
                        .tag(0)
                    BasicInfoView(userName: $userName, userAge: $userAge, userSchool: $userSchool, userGender: $userGender)
                        .tag(1)
                    InterestsView(selectedInterests: $selectedInterests, allInterests: allInterests)
                        .tag(2)
                    MatchView(userManager: userManager, currentStep: $currentStep)
                        .tag(3)
                    ChatView(userManager: userManager)
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                if currentStep < steps.count - 1 && currentStep != 3 {
                    Button("Next") {
                        if currentStep == 2 {
                            saveUserAndFindMatches()
                        }
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .navigationBarTitle(steps[currentStep])
        }
    }

    private func saveUserAndFindMatches() {
        guard let age = Int(userAge) else { return }
        userManager.saveUser(name: userName, age: age, school: userSchool, gender: userGender, interests: Array(selectedInterests))
        userManager.findMatches()
    }
}

struct MatchView: View {
    @ObservedObject var userManager: UserManager
    @Binding var currentStep: Int

    var body: some View {
        VStack {
            if let currentUser = userManager.currentUser {
                Text("Matches for \(currentUser.name)")
                    .font(.title)
                Text("Based on interests:")
                    .font(.subheadline)
                ForEach(currentUser.interests, id: \.self) { interest in
                    Text(interest)
                }

                List(userManager.matches) { match in
                    Button(action: {
                        userManager.selectMatch(match)
                        withAnimation {
                            currentStep += 1
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(match.name)
                                .font(.headline)
                            Text("Age: \(match.age)")
                            Text("School: \(match.school)")
                            Text("Interests: \(match.interests.joined(separator: ", "))")
                        }
                    }
                }
            } else {
                Text("No user data available")
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var userManager: UserManager
    @State private var newMessage = ""

    var body: some View {
        VStack {
            if let match = userManager.selectedMatch {
                Text("Chat with \(match.name)")
                    .font(.title)
                
                ScrollView {
                    ForEach(userManager.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                
                HStack {
                    TextField("Type a message", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        if !newMessage.isEmpty {
                            userManager.addMessage(newMessage, isFromMatch: false)
                            newMessage = ""
                        }
                    }
                }.padding()
            } else {
                Text("No match selected")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromMatch {
                Spacer()
            }
            Text(message.content)
                .padding()
                .background(message.isFromMatch ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            if !message.isFromMatch {
                Spacer()
            }
        }.padding(.horizontal)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to IntroLink")
                .font(.largeTitle)
            Text("Connect with like-minded individuals")
                .font(.subheadline)
        }
    }
}

struct BasicInfoView: View {
    @Binding var userName: String
    @Binding var userAge: String
    @Binding var userSchool: String
    @Binding var userGender: String

    var body: some View {
        Form {
            TextField("Name", text: $userName)
            TextField("Age", text: $userAge)
                .keyboardType(.numberPad)
            TextField("School/University", text: $userSchool)
            Picker("Gender", selection: $userGender) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
                Text("Other").tag("Other")
            }
        }
    }
}

struct InterestsView: View {
    @Binding var selectedInterests: Set<String>
    let allInterests: [String]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(allInterests, id: \.self) { interest in
                    InterestButton(interest: interest, isSelected: selectedInterests.contains(interest)) {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
        }
    }
}

struct InterestButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(interest)
                .padding()
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
