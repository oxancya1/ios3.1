import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.clear, lineWidth: 1)
            )
    }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let date: Date
    var isCompleted: Bool = false
}

struct ContentView: View {
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var tasks: [Task] = []
    @State private var isDatePickerVisible = false
    @State private var isSettingsVisible = false
    @State private var isDarkMode = false
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            HStack() {
                Text("Tasks")
                    .font(.title)
                Spacer()
                Button(action: openSetting) {
                    Text("Settings")
                        .foregroundColor(.white)
                    Image(systemName: isSettingsVisible ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 30)
                .background(Color.black)
                .cornerRadius(8)
            }

            TextField("Task Name", text: $name)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)

            TextField("Description", text: $description)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                isDatePickerVisible.toggle()
            }) {
                HStack {
                    Text("Due Date: \(dateFormatter.string(from: date))")
                        .padding()
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: isDatePickerVisible ? "chevron.up" : "chevron.down")
                        .padding()
                        .foregroundColor(.gray)
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal)

            if isDatePickerVisible {
                DatePicker("Select a date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.horizontal)
            }

            Button(action: addTask) {
                Text("Add Task")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            List {
                ForEach(tasks) { task in
                    taskRow(for: task)
                }
                .onDelete(perform: deleteTask)
            }
            .frame(maxHeight: 500)

            Spacer()
        }
        .padding()
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $isSettingsVisible) {
            SettingsView(isDarkMode: $isDarkMode)
        }
        .onAppear(perform: loadTasks)
    }
    
    private func addTask() {
        let newTask = Task(name: name, description: description, date: date)
        tasks.append(newTask)
        name = ""
        description = ""
        date = Date()
        SaveTask()
    }
    
    private func openSetting() {
        withAnimation {
            isSettingsVisible.toggle()
        }
    }
    
    private func taskRow(for task: Task) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                Text(task.description)
                    .font(.subheadline)
                    //
                Text("\(task.date, formatter: dateFormatter)")
                    .font(.footnote)
                    .foregroundColor(dateColor(eventDate: task.date))
            }
            Spacer()
            Button(action: {
                SaveTask()
            }) {
                Text("Save")
                    .padding(6)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(8)
    }
    
    private func dateColor(eventDate: Date) -> Color {
        return eventDate < Date() ? .red : .primary
    }
    
    private func SaveTask() {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("tasks.json")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            do {
                let data = try encoder.encode(tasks)
                try data.write(to: fileURL)
                print("Задачі збережено в tasks.json.")
            } catch {
                print("Помилка при збереженні JSON файлу: \(error)")
            }
        }
    }

    private func loadTasks() {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("tasks.json")
            
            if fileManager.fileExists(atPath: fileURL.path) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    let data = try Data(contentsOf: fileURL)
                    tasks = try decoder.decode([Task].self, from: data)
                    print("Задачі завантажено з tasks.json.")
                } catch {
                    print("Помилка при завантаженні JSON файлу: \(error)")
                }
            } else {
                print("Файл tasks.json не знайдений.")
            }
        }
    }

    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        SaveTask()
    }

    private func Over(_ taskDate: Date) -> Bool {
        return taskDate < Date()
    }
}

struct SettingsView: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        NavigationView {
            Form {
                Toggle("Theme", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    ContentView()
}

