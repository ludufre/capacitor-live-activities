import Foundation
import OSLog
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

@available(iOS 16.2, *)
@objc public class LiveActivities: NSObject {
    @objc public static let shared = LiveActivities()
    
    private var activities: [String: Activity<DynamicActivityAttributes>] = [:]
    
    private override init() {
        super.init()
        let bundleId = Bundle.main.bundleIdentifier ?? "com.app"
        SharedDataManager.shared.appGroupIdentifier = "group.\(bundleId).liveactivities"
    }
    
    private func syncExistingActivities() async {
        for activity in Activity<DynamicActivityAttributes>.activities {
            let activityId = activity.attributes.activityId
            activities[activityId] = activity
            
            Logger.viewCycle.error("🔄 Recovered existing activity: \(activityId)")
        }
    }
    
    @objc public func startActivity(
        layout: String,
        dynamicIslandLayout: String,
        behavior: String,
        data: [String: Any],
        staleDate: Date?,
        relevanceScore: Double
    ) async throws -> [String: String] {
        let activityId = UUID().uuidString
        
        let attributes = DynamicActivityAttributes(
            activityId: activityId,
            layoutJSON: layout,
            dynamicIslandLayoutJSON: dynamicIslandLayout,
            behaviorJSON: behavior
        )
        
        // Converter dados para AnyCodable do framework
        let contentState = DynamicActivityAttributes.ContentState(
            data: data.mapValues { AnyCodable($0) },
            activityId: activityId
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: staleDate,
            relevanceScore: relevanceScore > 0 ? relevanceScore : 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: .token
            )
            
            activities[activityId] = activity

            // Wait for the first push token
            guard let tokenData = await activity.pushTokenUpdates.first(where: { _ in true }) else {
                throw NSError(domain: "LiveActivities", code: 1, userInfo: [NSLocalizedDescriptionKey: "No push token received"])
            }

            // Convert token data to hex string
            let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
            
            Logger.viewCycle.error("✅ Started activity with custom ID: \(activityId)")
            Logger.viewCycle.error("🔍 System ID: \(activity.id)")
            Logger.viewCycle.error("📲 Push token: \(tokenString)")
            Logger.viewCycle.error("📊 Total activities tracked: \(self.activities.count)")
            
            return [
                "activityId": activityId,
                "token": tokenString
            ]
        } catch {
            Logger.viewCycle.error("❌ Failed to start activity: \(error)")
            throw error
        }
    }
    
    @objc public func updateActivity(
        activityId: String,
        data: [String: Any],
        alertConfig: [String: Any]?,
        behavior: [String: Any]?
    ) async throws {
        guard let activity = activities[activityId] else {
            // If not found, try to retrieve from the system
            await syncExistingActivities()
            
            // Tentar novamente
            guard activities[activityId] != nil else {
                Logger.viewCycle.error("❌ Activity not found: \(activityId)")
                Logger.viewCycle.error("📊 Available activities: \(self.activities.keys)")
                throw LiveActivitiesError.activityNotFound
            }
            
            return
        }
        
        if let sharedDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities") {
            sharedDefaults.set(data, forKey: "\(activityId)_data")
        }
        
        let contentState = DynamicActivityAttributes.ContentState(
            data: data.mapValues { AnyCodable($0) },
            activityId: activityId
        )
        
        var alertConfiguration: AlertConfiguration? = nil
        if let config = alertConfig {
            let title = config["title"] as? String ?? ""
            let body = config["body"] as? String ?? ""
            
            alertConfiguration = AlertConfiguration(
                title: LocalizedStringResource(stringLiteral: title),
                body: LocalizedStringResource(stringLiteral: body),
                sound: .default
            )
        }
        
        let updateContent = ActivityContent(state: contentState, staleDate: nil)
        
        
        await activity.update(
            updateContent,
            alertConfiguration: alertConfiguration
        )
        
        Logger.viewCycle.error("✅ Updated activity: \(activityId)")
    }
    
    @objc public func endActivity(
        activityId: String,
        finalData: [String: Any]?,
        behavior: [String: Any]?
    ) async throws {
        guard let activity = activities[activityId] else {
            // Tentar recuperar
            await syncExistingActivities()
            guard let activity = activities[activityId] else {
                throw LiveActivitiesError.activityNotFound
            }
            
            return
        }
        
        // Limpar dados do App Group
        if let sharedDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities") {
            sharedDefaults.removeObject(forKey: "\(activityId)_layout")
            sharedDefaults.removeObject(forKey: "\(activityId)_data")
        }
        
        let finalContentState = finalData.map {
            DynamicActivityAttributes.ContentState(
                data: $0.mapValues { AnyCodable($0) },
                activityId: activityId
            )
        }
        
        let finalContent: ActivityContent<DynamicActivityAttributes.ContentState>? = finalContentState.map {
            ActivityContent(state: $0, staleDate: nil)
        }
        
        await activity.end(
            finalContent,
            dismissalPolicy: .default
        )
        
        activities.removeValue(forKey: activityId)
        Logger.viewCycle.error("✅ Ended activity: \(activityId)")
    }
    
    @objc public func getAllActivities() async -> [[String: Any]] {
        // Sincronizar com activities do sistema
        await syncExistingActivities()
        
        return activities.compactMap { (id, activity) in
            // Converter ActivityState para String
            let stateString: String
            switch activity.activityState {
            case .active:
                stateString = "active"
            case .ended:
                stateString = "ended"
            case .dismissed:
                stateString = "dismissed"
            case .stale:
                stateString = "stale"
            @unknown default:
                stateString = "unknown"
            }
            
            return [
                "id": id,
                "state": stateString,
                "systemId": activity.id
            ]
        }
    }
    
    @objc public func getActivity(byId activityId: String) -> [String: Any] {
        let activity = activities[activityId]
        
        let stateString: String
        switch activity?.activityState {
        case .active:
            stateString = "active"
        case .ended:
            stateString = "ended"
        case .dismissed:
            stateString = "dismissed"
        case .stale:
            stateString = "stale"
        @unknown default:
            stateString = "unknown"
        }
        
        return [
            "id": activityId,
            "state": stateString,
            "systemId": activity?.id ?? ""
        ]
    }
    
    @objc public func debugPrintActivities() {
        Logger.viewCycle.error("🔍 === DEBUG ACTIVITIES ===")
           
        Logger.viewCycle.error("📊 Tracked activities count: \(self.activities.count)")
        
        for (customId, activity) in activities {
            Logger.viewCycle.error("Activity:")
            Logger.viewCycle.error("  - Custom ID: \(customId)")
            Logger.viewCycle.error("  - System ID: \(activity.id)")
        }
        
        Logger.viewCycle.error("\n📱 System activities:")
        for activity in Activity<DynamicActivityAttributes>.activities {
            Logger.viewCycle.error("  - System ID: \(activity.id)")
            Logger.viewCycle.error("  - Our ID: \(activity.attributes.activityId)")
        }
        
        
        Logger.viewCycle.error("========================")
    }
    
    @objc func saveImageForLiveActivities(
        image: UIImage,
        withName name: String,
        compressionQuality: CGFloat = 0.8
    ) -> Bool {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities"
        ) else {
            Logger.viewCycle.error("❌ Failed to get App Group container")
            return false
        }
        
        // Create directory if it does not exist
        let imagesDirectory = containerURL.appendingPathComponent("LiveActivitiesImages")
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        
        // Comprimir e salvar imagem
        let imageURL = imagesDirectory.appendingPathComponent(name)
        
        // Tentar JPEG primeiro, depois PNG
        if let jpegData = image.jpegData(compressionQuality: compressionQuality) {
            do {
                try jpegData.write(to: imageURL)
                Logger.viewCycle.error("✅ Saved image: \(name) (\(jpegData.count) bytes)")
                return true
            } catch {
                Logger.viewCycle.error("❌ Failed to save JPEG: \(error)")
            }
        }
        
        if let pngData = image.pngData() {
            do {
                try pngData.write(to: imageURL)
                Logger.viewCycle.error("✅ Saved PNG image: \(name) (\(pngData.count) bytes)")
                return true
            } catch {
                Logger.viewCycle.error("❌ Failed to save PNG: \(error)")
            }
        }
        
        return false
    }
    
    /// Remove uma imagem do App Group
    @objc public func removeImageFromLiveActivities(withName name: String) -> Bool {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities"
        ) else {
            return false
        }
        
        let imageURL = containerURL
            .appendingPathComponent("LiveActivitiesImages")
            .appendingPathComponent(name)
        
        do {
            try FileManager.default.removeItem(at: imageURL)
            Logger.viewCycle.error("✅ Removed image: \(name)")
            return true
        } catch {
            Logger.viewCycle.error("❌ Failed to remove image: \(error)")
            return false
        }
    }
    
    /// Lista todas as imagens salvas no App Group
    @objc public func listSavedImages() -> [String] {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities"
        ) else {
            return []
        }
        
        let imagesDirectory = containerURL.appendingPathComponent("LiveActivitiesImages")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)
            return files.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") }
        } catch {
            return []
        }
    }
    
    /// Limpa imagens antigas (mais de 7 dias)
    @objc public func cleanupOldImages() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier ?? "").LiveActivities"
        ) else {
            return
        }
        
        let imagesDirectory = containerURL.appendingPathComponent("LiveActivitiesImages")
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.creationDateKey])
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    try? fileManager.removeItem(at: file)
                    Logger.viewCycle.error("🧹 Cleaned up old image: \(file.lastPathComponent)")
                }
            }
        } catch {
            Logger.viewCycle.error("❌ Failed to cleanup images: \(error)")
        }
    }
    
}


enum LiveActivitiesError: LocalizedError {
    case activityNotFound
    case invalidLayout
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .activityNotFound:
            return "Activity not found"
        case .invalidLayout:
            return "Invalid layout JSON"
        case .notSupported:
            return "Live Activities not supported"
        }
    }
}
