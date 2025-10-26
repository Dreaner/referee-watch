//
//  NoteInputView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 26/10/25.
//


import SwiftUI

struct NoteInputView: View {
    @Binding var refereeNote: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Add Referee Note")
                .font(.headline)
                .padding(.bottom, 4)

            // ✅ 在 watchOS 上使用 TextField 替代 TextEditor
            TextField("Enter note...", text: $refereeNote)
                .multilineTextAlignment(.center)
                .frame(height: 30)

            Button("Done") {
                dismiss()
            }
            .padding(.top, 6)
        }
        .padding()
    }
}

