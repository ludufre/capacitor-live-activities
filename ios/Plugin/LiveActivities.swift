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

    /// Assigned by the bridge plugin: forwards every APNs live-activity push
    /// token emitted by ActivityKit's `pushTokenUpdates` stream as
    /// `(activityId, hexEncodedToken)`.
    public var onPushTokenUpdate: ((String, String) -> Void)?
    private var observedTokenActivityIds = Set<String>()

    private override init() {
        super.init()
        let bundleId = Bundle.main.bundleIdentifier ?? "com.app"
        SharedDataManager.shared.appGroupIdentifier = "group.\(bundleId).liveactivities"
    }

    /// Observe the push token stream of an activity exactly once. Both
    /// `startActivity` and the recovery path funnel through here; the set
    /// dedupes so repeated syncs never spawn duplicate observer tasks.
    private func observePushToken(for activity: Activity<DynamicActivityAttributes>, activityId: String) {
        guard !observedTokenActivityIds.contains(activityId) else { return }
        observedTokenActivityIds.insert(activityId)
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                Logger.viewCycle.error("🔑 Push token updated for activity: \(activityId)")
                self.onPushTokenUpdate?(activityId, token)
            }
        }
    }

    private func syncExistingActivities() async {
        for activity in Activity<DynamicActivityAttributes>.activities {
            let activityId = activity.attributes.activityId
            activities[activityId] = activity
            observePushToken(for: activity, activityId: activityId)

            Logger.viewCycle.error("🔄 Recovered existing activity: \(activityId)")
        }
    }
    
    @objc public func startActivity(
        layout: String,
        dynamicIslandLayout: String,
        behavior: String,
        data: [String: Any],
        staleDate: Date?,
        relevanceScore: Double,
        
        
    ) throws -> String {
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
            // Request a token-backed activity so remote updates via APNs are
            // possible (see the 'activityPushToken' listener event). If the
            // token-backed request fails — e.g. the app has no push
            // entitlement — fall back to a plain request instead of failing
            // the start.
            let activity: Activity<DynamicActivityAttributes>
            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: .token
                )
            } catch {
                Logger.viewCycle.error("⚠️ Token-backed request failed, retrying without push: \(error)")
                activity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: nil
                )
            }

            activities[activityId] = activity
            observePushToken(for: activity, activityId: activityId)

            Logger.viewCycle.error("✅ Started activity with custom ID: \(activityId)")
            Logger.viewCycle.error("🔍 System ID: \(activity.id)")
            Logger.viewCycle.error("📊 Total activities tracked: \(self.activities.count)")
            
            return activityId
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
        // If not tracked in memory (e.g. after an app relaunch), try to
        // recover from the system, then fall through to the actual update —
        // previously the recovery path returned without applying the update.
        if activities[activityId] == nil {
            await syncExistingActivities()
        }
        guard let activity = activities[activityId] else {
            Logger.viewCycle.error("❌ Activity not found: \(activityId)")
            Logger.viewCycle.error("📊 Available activities: \(self.activities.keys)")
            throw LiveActivitiesError.activityNotFound
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
        behavior: [String: Any]?,
        dismissalPolicy: String?,
        dismissalDate: Date?
    ) async throws {
        // If not tracked in memory (e.g. after an app relaunch), try to
        // recover from the system, then fall through to the actual end call —
        // previously the recovery path returned WITHOUT ending the recovered
        // activity, so an activity could never be ended once the app process
        // had been restarted.
        if activities[activityId] == nil {
            await syncExistingActivities()
        }
        guard let activity = activities[activityId] else {
            throw LiveActivitiesError.activityNotFound
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
        
        // Map the caller-selected dismissal policy. "immediate" removes the
        // ended activity from the Lock Screen right away, "after" keeps it
        // until the given date (the system caps this at four hours), and the
        // default keeps Apple's behavior (linger for up to four hours).
        let policy: ActivityUIDismissalPolicy
        switch dismissalPolicy {
        case "immediate":
            policy = .immediate
        case "after":
            if let dismissalDate {
                policy = .after(dismissalDate)
            } else {
                policy = .default
            }
        default:
            policy = .default
        }

        await activity.end(
            finalContent,
            dismissalPolicy: policy
        )

        activities.removeValue(forKey: activityId)
        observedTokenActivityIds.remove(activityId)
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
