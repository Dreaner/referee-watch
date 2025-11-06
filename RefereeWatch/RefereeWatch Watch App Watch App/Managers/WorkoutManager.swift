//
//  WorkoutManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 6/11/25.
//

import Foundation
import HealthKit
import Combine

// 这是一个 HealthKit 权限和会话管理工具
class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published private(set) var running: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0 // HealthKit 记录的总时间
    
    override init() {
        super.init()
        // 🚨 注意：首次运行时，App 会要求 HealthKit 权限
        requestAuthorization()
    }
    
    // MARK: - 权限请求
    private func requestAuthorization() {
        // 只需要请求足球运动所需的时间、心率和距离权限
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
            
            // 设置数据源
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            // 启动会话
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { success, error in
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
        }
    }
    
    func pauseWorkout() {
        session?.pause()
        running = false
        print("⏸️ Workout Session Paused.")
    }
    
    func resumeWorkout() {
        session?.resume()
        running = true
        print("▶️ Workout Session Resumed.")
    }
    
    func endWorkout() {
        // 结束会话
        session?.end()
        running = false
        print("⏹️ Workout Session Ended.")
    }
    
    private func resetState() {
        DispatchQueue.main.async {
            self.elapsedTime = 0
            self.session = nil
            self.builder = nil
        }
    }
}

// MARK: - HKWorkoutSessionDelegate (确保这个 delegate 存在且正确)
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                print("Session changed to Running")
            case .paused:
                print("Session changed to Paused")
            case .ended:
                print("Session changed to Ended")
                
                // ✅ 关键修复点：当 Session 状态变为 .ended 时，才结束 Builder 并保存 Workout
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
            self.elapsedTime = workoutBuilder.elapsedTime
            // 可以在这里处理心率、距离等数据的更新
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 监听会话事件
    }
}
