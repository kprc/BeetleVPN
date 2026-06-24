//
//  TrafficView.swift
//  BeetleVPN
//
//  Created by rickey on 6/5/26.
//

import SwiftUI

struct TrafficLabelView: View {

    @ObservedObject var trafficManager: TrafficManager

    var body: some View {

        HStack(spacing: 5) {

            Image(systemName: "network")

            VStack(alignment: .leading, spacing: 0) {

                Text("↑\(trafficManager.uploadSpeed)")
                    .font(.system(size: 9, design: .monospaced))

                Text("↓\(trafficManager.downloadSpeed)")
                    .font(.system(size: 9, design: .monospaced))
            }
        }
    }
}
