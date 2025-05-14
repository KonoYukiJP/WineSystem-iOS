import SwiftUI

struct TestView2: View {
    let icons: [String] = (1...30).map { _ in "square" } // SF Symbols例
    let iconsPerPage = 10
    
    var pages: [[String]] {
        stride(from: 0, to: icons.count, by: iconsPerPage).map {
            Array(icons[$0..<min($0 + iconsPerPage, icons.count)])
        }
    }

    var body: some View {
        TabView {
            ForEach(pages.indices, id: \.self) { index in
                let pageIcons = pages[index]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                    ForEach(pageIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .padding()
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    }
}

#Preview {
    TestView2()
}
