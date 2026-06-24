//
//  TrafficManager.swift
//  BeetleVPN
//
//  Created by rickey on 6/4/26.
//

import SwiftUI
import Combine
import Macdss

class TrafficManager: ObservableObject {
    @Published var uploadSpeed: String = "0 KB/s"
    @Published var downloadSpeed: String = "0 KB/s"
    
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTrafficSpeed()
            }
    }
    
    private func refreshTrafficSpeed() {
        uploadSpeed = DrawinBeetleLibGetUpLink()
        downloadSpeed = DrawinBeetleLibGetDownLink()
    }
    
    deinit {
        timer?.cancel()
    }
}
