//
//  KeypadNumberInputSheet.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 14/11/25.
//

import SwiftUI
import WatchKit

// MARK: - Custom Button Style for Press Animation
struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct KeypadNumberInputSheet: View {
    @Binding var selectedNumber: Int?
    var onConfirm: () -> Void
    
    @State private var inputString: String = ""
    @FocusState private var isVoiceInputActive: Bool
    
    private let maxDigits = 3
    // 最终确定的 UI 参数
    private let buttonHeight: CGFloat = 40
    private let buttonCornerRadius: CGFloat = 20 // 设置为按钮高度的一半，形成更圆的药丸形状
    private let keypadSpacing: CGFloat = 4
    private let paddingVertical: CGFloat = 10

    // MARK: - Button Style
    private func createNumberButton(digit: Int) -> some View {
        Button(action: { appendDigit(digit) }) {
            Text("\(digit)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: buttonHeight, idealHeight: buttonHeight, maxHeight: buttonHeight)
                .background(Color.gray.opacity(0.4))
                .cornerRadius(buttonCornerRadius)
        }
        .buttonStyle(.plain)
    }

    // MARK: Body
    var body: some View {
        Grid(horizontalSpacing: keypadSpacing, verticalSpacing: 5) {
            // MARK: - Display Area
            GridRow {
                Text(inputString.isEmpty ? "No." : inputString)
                    .font(.largeTitle) // 从 .title 改为 .largeTitle，使字体更大
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                    .gridCellColumns(3) // 更新：让显示区域占据全部三列
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .center) // 增加最小高度以稳定布局
            }

            // MARK: - Keypad Grid
            GridRow {
                createNumberButton(digit: 1)
                createNumberButton(digit: 2)
                createNumberButton(digit: 3)
            }
            GridRow {
                createNumberButton(digit: 4)
                createNumberButton(digit: 5)
                createNumberButton(digit: 6)
            }
            GridRow {
                createNumberButton(digit: 7)
                createNumberButton(digit: 8)
                createNumberButton(digit: 9)
            }
            GridRow {
                // 语音输入按钮
                Button(action: {
                    isVoiceInputActive = true
                }) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                }
                .tint(.orange)
                .frame(maxWidth: .infinity, minHeight: buttonHeight, idealHeight: buttonHeight, maxHeight: buttonHeight)
                
                createNumberButton(digit: 0)
                
                // 数字删除按钮
                Button(action: deleteDigit) {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                }
                .tint(.red)
                .frame(maxWidth: .infinity, minHeight: buttonHeight, idealHeight: buttonHeight, maxHeight: buttonHeight)
            }
        }
        .padding(.vertical, paddingVertical)
        .padding(.horizontal, 5)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    confirmInput()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(inputString.isEmpty || Int(inputString) == 0)
            }
        }
        .onChange(of: inputString) {
            // 确保输入始终是数字且不超过最大长度
            let filtered = inputString.filter { $0.isNumber }
            if filtered.count > maxDigits {
                inputString = String(filtered.prefix(maxDigits))
            } else if filtered != inputString {
                inputString = filtered
            }
        }
        .background {
            // 隐藏的 TextField, 用于触发系统键盘/语音输入
            TextField("Number input", text: $inputString)
                .focused($isVoiceInputActive)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
    }
    
    // MARK: - Logic (保持不变)
    private func appendDigit(_ digit: Int) {
        if inputString.count < maxDigits {
            if inputString.isEmpty && digit == 0 {
                return
            }
            inputString.append("\(digit)")
        }
    }
    
    private func deleteDigit() {
        if !inputString.isEmpty {
            inputString.removeLast()
        }
    }
    
    private func confirmInput() {
        if let number = Int(inputString), number > 0 {
            selectedNumber = number
            onConfirm()
        } else {
            WKInterfaceDevice.current().play(.failure)
        }
    }
}


// MARK: - Preview
#Preview {
    // 包装在一个本地结构体中，以便为 @Binding 提供状态
    struct Wrapper: View {
        @State var num: Int? = 10
        var body: some View {
            // 将视图包装在 NavigationStack 中以在预览中显示工具栏
            NavigationStack {
                KeypadNumberInputSheet(selectedNumber: $num) {
                    print("Confirmed: \(num ?? 0)")
                }
            }
        }
    }
    return Wrapper()
}
