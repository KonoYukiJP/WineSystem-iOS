import SwiftUI

struct TestView2: View {
    @State private var showPopup: Bool = false
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var years: [Int] = Array((Calendar.current.component(.year, from: Date()) - 20)...(Calendar.current.component(.year, from: Date()) + 10))

    var body: some View {
        ZStack {
            VStack {
                Button("Select Year") {
                    withAnimation {
                        showPopup.toggle()
                    }
                }
                .padding()
                Text("Selected Year: \(selectedYear)")
            }
            
            if showPopup {
                Color.black.opacity(0.4) // 背景を暗くする
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showPopup = false
                        }
                    }

                VStack {
                    Text("Select Year")
                    Picker("Select Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150)
                    .padding()
                    
                    Button("Done") {
                        withAnimation {
                            showPopup = false
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .frame(width: 300, height: 300)
                .transition(.move(edge: .bottom)) // アニメーション
            }
        }
    }
}

#Preview {
    TestView2()
}
