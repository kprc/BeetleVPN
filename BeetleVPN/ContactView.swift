//
//  ContactView.swift
//  BeetleVPN
//
//  Created by rickey on 6/5/26.
//

import SwiftUI

struct ContactView: View {

    @State private var email = ""
    @State private var telegram = ""

    var onSubmit: (_ email: String, _ telegram: String) -> Void

    private var canContinue: Bool {

        !email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        ||
        !telegram
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {

        VStack(spacing: 20) {

            Image(systemName: "network")
                .font(.system(size: 48))

            Text("Welcome to Beetle VPN")
                .font(.largeTitle)
                .bold()

            Text("""
Please provide at least one contact method.

This information is only used for important service announcements, software updates, and network maintenance notifications.
""")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {

                Text("Email")

                TextField(
                    "your@email.com",
                    text: $email
                )
                .textFieldStyle(.roundedBorder)

                Text("Telegram")

                TextField(
                    "@username",
                    text: $telegram
                )
                .textFieldStyle(.roundedBorder)
            }

            Divider()

            Link(
                "Join Official Telegram Group",
                destination: URL(
                    string: "https://t.me/beetlevpn"
                )!
            )

            Spacer()

            Button("Continue") {

                onSubmit(
                    email.trimmingCharacters(in: .whitespacesAndNewlines),
                    telegram.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .disabled(!canContinue)
        }
        .padding(30)
        .frame(width: 520, height: 420)
    }
}
