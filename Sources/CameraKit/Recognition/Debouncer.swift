//
//  Debouncer.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 2/3/25.
//

import Foundation

actor Debouncer {
    private var endTime: Date = .distantPast

    func perform(minimumDuration: TimeInterval, work: @escaping @Sendable () async -> Void) async {
        let startTime = Date.now

        guard startTime >= endTime else { return }
                
        await work()
        
        // Ensure minimum duration by sleeping if needed
        let elapsedTime = Date.now.timeIntervalSince(startTime)
        let remainingTime = max(minimumDuration - elapsedTime, 0)
        if remainingTime > 0 {
            try? await Task.sleep(for: .seconds(remainingTime))
        }
        
        // Update endTime for the next caller
        endTime = Date.now + minimumDuration
    }
}
