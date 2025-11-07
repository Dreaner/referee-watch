//
//  WorkoutManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 6/11/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Managers/WorkoutManager.swift (最终修复版：精准计时启动)

import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published private(set) var running: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    private var localTimer: Timer?
    // ✅ 关键：本地计时器的起点，与 HealthKit Session 的起点同步
    private var localTimeStart: Date? = nil
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - 权限请求 (保持不变)
    private func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("✅ HealthKit Authorization granted.")
            } else if let error = error {
                print("❌ HealthKit Authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 会话控制
    
    func startWorkout(sport: HKWorkoutActivityType = .soccer) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = sport
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            // Session 启动
            let startDate = Date()
            session?.startActivity(with: startDate)
            
            // ✅ 关键修复 1：将本地计时起点设置为 Session 的起点
            localTimeStart = startDate
            
            // 混合启动：立即启动本地计时器，提供瞬时 UI 反馈
            localTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                guard let self = self, let start = self.localTimeStart else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
            
            builder?.beginCollection(withStart: startDate) { success, error in
                guard success else {
                    print("❌ Builder failed to begin collection: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    self.running = true
                    print("✅ Workout Session Started.")
                }
            }
        } catch {
            print("❌ Error starting workout session: \(error.localizedDescription)")
            self.stopLocalTimer()
        }
    }
    
    // ⚠️ 移除 pauseWorkout/resumeWorkout 引用

    func endWorkout() {
        session?.end()
        running = false
        print("⏹️ Workout Session Ended.")
        self.stopLocalTimer()
    }
    
    // MARK: - Local Timer Management (保持不变)
    private func stopLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
        localTimeStart = nil
    }
    
    private func resetState() {
        DispatchQueue.main.async {
            self.elapsedTime = 0
            self.session = nil
            self.builder = nil
            self.stopLocalTimer()
        }
    }
}

// MARK: - HKWorkoutSessionDelegate & HKLiveWorkoutBuilderDelegate (保持不变)
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .ended:
                self.builder?.endCollection(withEnd: Date()) { (success, error) in
                    self.builder?.finishWorkout { (workout, error) in
                        guard workout != nil else {
                            print("❌ Failed to finish workout: \(error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        print("💾 Workout saved to Health App.")
                        self.resetState()
                    }
                }
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Session failed with error: \(error.localizedDescription)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        DispatchQueue.main.async {
            // 当 HealthKit 开始推送数据时，停止本地计时器
            if self.localTimer != nil {
                self.stopLocalTimer()
                print("✅ HealthKit sync achieved, switched to precise time source.")
            }
            // 切换到 HealthKit 的精确时间
            self.elapsedTime = workoutBuilder.elapsedTime
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
