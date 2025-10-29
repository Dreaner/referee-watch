//
//  ProfileView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Referee User")
                .font(.title)
                .bold()
            
            Text("Matches Managed: \(connectivityManager.allReports.count)")
                .foregroundColor(.secondary)
            
            Button("Sync Data") {
                // TODO: 加入同步逻辑
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView(connectivityManager: iPhoneConnectivityManager.shared)
}
