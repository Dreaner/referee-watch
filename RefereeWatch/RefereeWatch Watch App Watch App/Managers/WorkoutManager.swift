//
//  WorkoutManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 6/11/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Managers/WorkoutManager.swift

import Foundation
import HealthKit
import Combine
import CoreLocation

class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    // ✅ 关键：routeBuilder 必须被声明为可选类型 (?)
    private var routeBuilder: HKWorkoutRouteBuilder?
    
    @Published private(set) var running: Bool = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    private var localTimer: Timer?
    private var localTimeStart: Date? = nil
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - 权限请求
    private func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKSeriesType.workoutRoute()
        ]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSeriesType.workoutRoute()
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
            
            // 因为 routeBuilder 是可选的，所以这里的初始化也是安全的
            routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            session?.startActivity(with: startDate)
            localTimeStart = startDate
            
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
    

    func endWorkout() {
        session?.end()
        running = false
        print("⏹️ Workout Session Ended.")
        self.stopLocalTimer()
    }
    
    // MARK: - Local Timer Management
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
            self.routeBuilder = nil
            self.stopLocalTimer()
        }
    }
}

// MARK: - HKWorkoutSessionDelegate & HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .ended:
                self.builder?.endCollection(withEnd: Date()) { (success, error) in
                    self.builder?.finishWorkout { (workout, error) in
                        guard let workout = workout else {
                            print("❌ Failed to finish workout: \(error?.localizedDescription ?? "Unknown error")")
                            self.resetState()
                            return
                        }
                        
                        print("💾 Workout saved to Health App.")
                        
                        // ✅ 关键：检查 routeBuilder 是否存在，然后安全地调用它的方法
                        guard let routeBuilder = self.routeBuilder else {
                            // 如果没有 routeBuilder，直接重置状态
                            self.resetState()
                            return
                        }
                        
                        routeBuilder.finishRoute(with: workout, metadata: nil) { (route, error) in
                            if let error = error {
                                print("❌ Error finishing route: \(error.localizedDescription)")
                            } else if route != nil {
                                print("💾 Route saved to workout successfully.")
                            }
                            
                            // 无论路线是否成功保存，这都是最后一步，所以在这里重置状态
                            self.resetState()
                        }
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
            if self.localTimer != nil {
                self.stopLocalTimer()
                print("✅ HealthKit sync achieved, switched to precise time source.")
            }
            self.elapsedTime = workoutBuilder.elapsedTime
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
