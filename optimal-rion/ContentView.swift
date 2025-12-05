//
//  ContentView.swift
//  optimal-rion
//
//  Created by Kota Yatagai on 2025/10/07.
//

import SwiftUI

enum CommuteMode: String, CaseIterable, Identifiable {
    case toSchool = "登校"
    case toHome = "下校"
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var selectedMode: CommuteMode = .toSchool

    var body: some View {
        TabView(selection: $selectedMode) {
            DashboardView(mode: .toSchool)
                .tabItem {
                    Image(systemName: "sun.horizon")
                    Text(CommuteMode.toSchool.rawValue)
                }
                .tag(CommuteMode.toSchool)

            DashboardView(mode: .toHome)
                .tabItem {
                    Image(systemName: "house")
                    Text(CommuteMode.toHome.rawValue)
                }
                .tag(CommuteMode.toHome)
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentView()
}
