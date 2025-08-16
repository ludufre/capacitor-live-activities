import Foundation
import Capacitor
import Compression

#if canImport(ActivityKit)
import ActivityKit
#endif

@objc(LiveActivitiesPlugin)
public class LiveActivitiesPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivitiesPlugin"
    public let jsName = "LiveActivities"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getAllActivities", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "areActivitiesEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "debugActivities", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listImages", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "cleanupImages", returnType: CAPPluginReturnPromise)
    ]
    
    // MARK: - Compression Analysis
    
    struct CompressionDecision {
        let shouldCompress: Bool
        let reason: String
        let totalSize: Int
        let layoutSize: Int
        let dynamicIslandSize: Int
    }
    
    private func analyzeCompressionNeeds(
        layoutDict: [String: Any],
        dynamicIslandDict: [String: Any],
        behaviorDict: [String: Any],
        data: [String: Any],
        staleDate: Double?,
        relevanceScore: Double?
    ) -> CompressionDecision {
        
        // Calculate individual component sizes
        let layoutJSON = try? JSONSerialization.data(withJSONObject: layoutDict)
        let layoutSize = layoutJSON?.count ?? 0
        
        let dynamicIslandJSON = try? JSONSerialization.data(withJSONObject: dynamicIslandDict)
        let dynamicIslandSize = dynamicIslandJSON?.count ?? 0
        
        let dataJSON = try? JSONSerialization.data(withJSONObject: data)
        let dataSize = dataJSON?.count ?? 0
        
        let behaviorJSON = try? JSONSerialization.data(withJSONObject: behaviorDict)
        let behaviorSize = behaviorJSON?.count ?? 0
        
        // Calculate total payload size including all components
        var totalPayload: [String: Any] = [
            "layout": layoutDict,
            "data": data,
            "dynamicIslandLayout": dynamicIslandDict,
            "behavior": behaviorDict
        ]
        
        if let staleDate = staleDate {
            totalPayload["staleDate"] = staleDate
        }
        
        if let relevanceScore = relevanceScore {
            totalPayload["relevanceScore"] = relevanceScore
        }
        
        guard let totalPayloadJSON = try? JSONSerialization.data(withJSONObject: totalPayload) else {
            return CompressionDecision(
                shouldCompress: false,
                reason: "Failed to serialize payload for analysis",
                totalSize: 0,
                layoutSize: layoutSize,
                dynamicIslandSize: dynamicIslandSize
            )
        }
        
        let totalSize = totalPayloadJSON.count
        
        print("📊 Payload Analysis:")
        print("   • Main Layout: \(layoutSize) bytes")
        print("   • Dynamic Island: \(dynamicIslandSize) bytes")
        print("   • Data: \(dataSize) bytes")
        print("   • Behavior: \(behaviorSize) bytes")
        print("   • Total: \(totalSize) bytes")
        
        if totalSize > 3000 {
            return CompressionDecision(
                shouldCompress: true,
                reason: "Total payload exceeds 3KB safety limit (\(totalSize) bytes)",
                totalSize: totalSize,
                layoutSize: layoutSize,
                dynamicIslandSize: dynamicIslandSize
            )
        }
        
        // No compression needed
        return CompressionDecision(
            shouldCompress: false,
            reason: "Payload within limits, no compression needed (\(totalSize) bytes)",
            totalSize: totalSize,
            layoutSize: layoutSize,
            dynamicIslandSize: dynamicIslandSize
        )
    }
    
    @objc func startActivity(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2+")
            return
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            call.reject("Live Activities are not enabled")
            return
        }

        
        guard let layoutDict = call.getObject("layout"),
              let layoutJSON = try? JSONSerialization.data(withJSONObject: layoutDict),
              let layoutString = String(data: layoutJSON, encoding: .utf8),
              let dynamicIslandDict = call.getObject("dynamicIslandLayout"),
              let dynamicIslandJSON = try? JSONSerialization.data(withJSONObject: dynamicIslandDict),
              let dynamicIslandString = String(data: dynamicIslandJSON, encoding: .utf8),
              let behaviorDict = call.getObject("behavior"),
              let behaviorJSON = try? JSONSerialization.data(withJSONObject: behaviorDict),
              let behaviorString = String(data: behaviorJSON, encoding: .utf8),
              let data = call.getObject("data") else {
            call.reject("Invalid parameters")
            return
        }
        
        // Validate Dynamic Island expanded regions
        if let expandedDict = dynamicIslandDict["expanded"] as? [String: Any] {
            let hasLeading = expandedDict["leading"] != nil
            let hasTrailing = expandedDict["trailing"] != nil
            let hasCenter = expandedDict["center"] != nil
            let hasBottom = expandedDict["bottom"] != nil
            
            if !hasLeading && !hasTrailing && !hasCenter && !hasBottom {
                call.reject("Dynamic Island expanded layout must have at least one region (leading, trailing, center, or bottom)")
                return
            }
            
            print("✅ Dynamic Island expanded validation passed - regions: leading:\(hasLeading), trailing:\(hasTrailing), center:\(hasCenter), bottom:\(hasBottom)")
        } else {
            call.reject("Dynamic Island expanded layout is required")
            return
        }
        
        // Comprehensive payload analysis for intelligent compression
        let compressionDecision = analyzeCompressionNeeds(
            layoutDict: layoutDict,
            dynamicIslandDict: dynamicIslandDict,
            behaviorDict: behaviorDict,
            data: data,
            staleDate: call.getDouble("staleDate"),
            relevanceScore: call.getDouble("relevanceScore")
        )
        
        var finalLayoutString = layoutString
        var finalDynamicIslandString = dynamicIslandString
        var finalBehaviorString = behaviorString
        
        if compressionDecision.shouldCompress {
            print("🗜️ Auto-enabling compression: \(compressionDecision.reason)")
            
            // Compress main layout
            if let compressedLayout = compressLayoutJSON(layoutString) {
                finalLayoutString = compressedLayout
                print("✅ Main layout compressed: \(layoutString.count) → \(compressedLayout.count) bytes")
            } else {
                print("❌ Main layout compression failed")
                call.reject("Failed to compress large activity data")
                return
            }
            
            // Compress Dynamic Island layout if present
            if let compressedDynamicIsland = compressLayoutJSON(dynamicIslandString) {
                finalDynamicIslandString = compressedDynamicIsland
                print("✅ Dynamic Island layout compressed: \(dynamicIslandString.count) → \(compressedDynamicIsland.count) bytes")
            } else {
                print("⚠️ Dynamic Island compression failed, using original")
            }
            
            if let compressedBehavior = compressLayoutJSON(behaviorString) {
                finalBehaviorString = compressedBehavior
                print("✅ Behavior compressed: \(dynamicIslandString.count) → \(compressedBehavior.count) bytes")
            } else {
                print("⚠️ Behavior compression failed, using original")
            }
            
        } else {
            print("✅ \(compressionDecision.reason)")
        }
        
        let staleTimestamp = call.getDouble("staleDate")
        let staleDate = staleTimestamp.map { Date(timeIntervalSince1970: $0 / 1000) } // JS timestamp em ms
        let relevanceScore = call.getDouble("relevanceScore") ?? 0
        
        Task {
            do {
                var activity: [String: String]
                activity = try await LiveActivities.shared.startActivity(
                    layout: finalLayoutString,
                    dynamicIslandLayout: finalDynamicIslandString,
                    behavior: finalBehaviorString,
                    data: data,
                    staleDate: staleDate,
                    relevanceScore: relevanceScore
                )
                
                call.resolve(activity)
            } catch {
                call.reject("Failed to start activity: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func updateActivity(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            guard let activityId = call.getString("activityId"),
                  let data = call.getObject("data") else {
                call.reject("Invalid parameters")
                return
            }
            
            let alertConfig = call.getObject("alertConfiguration")
            let behavior = call.getObject("behavior")
            
            Task {
                do {
                    try await LiveActivities.shared.updateActivity(
                        activityId: activityId,
                        data: data,
                        alertConfig: alertConfig,
                        behavior: behavior
                    )
                    
                    await MainActor.run {
                        call.resolve()
                    }
                } catch {
                    await MainActor.run {
                        call.reject("Failed to update activity: \(error.localizedDescription)")
                    }
                }
            }
        }else{
            call.reject("Live Activities require iOS 16.2+")
        }
    }
    
    @objc func endActivity(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            guard let activityId = call.getString("activityId") else {
                call.reject("Invalid parameters")
                return
            }
            
            let finalData = call.getObject("data")
            let behavior = call.getObject("behavior")
            
            Task {
                do {
                    try await LiveActivities.shared.endActivity(
                        activityId: activityId,
                        finalData: finalData,
                        behavior: behavior
                    )
                    
                    await MainActor.run {
                        call.resolve()
                    }
                } catch {
                    await MainActor.run {
                        call.reject("Failed to end activity: \(error.localizedDescription)")
                    }
                }
            }
        }else{
            call.reject("Live Activities require iOS 16.2+")
        }
    }
    
    @objc func getAllActivities(_ call: CAPPluginCall)  {
        if #available(iOS 16.2, *) {
            Task{
                let activities = await LiveActivities.shared.getAllActivities()
                
                call.resolve([
                    "activities": activities
                ])
            }
        }else{
            call.reject("Live Activities require iOS 16.2+")
        }
    }
    
    @objc func areActivitiesEnabled(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["enabled": false])
            return
        }
        
#if canImport(ActivityKit)
        call.resolve([
            "enabled": ActivityAuthorizationInfo().areActivitiesEnabled
        ])
#else
        call.resolve(["enabled": false])
#endif
    }
    
    @objc func debugActivities(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            LiveActivities.shared.debugPrintActivities()
        }
        call.resolve()
    }
    
    @objc func saveImage(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            guard let base64String = call.getString("imageData"),
                  let imageName = call.getString("name") else {
                call.reject("Missing required parameters")
                return
            }
            
            // Remover prefixo data:image se existir
            let base64 = base64String.replacingOccurrences(of: "data:image/[^;]+;base64,", with: "", options: .regularExpression)
            
            guard let imageData = Data(base64Encoded: base64),
                  let image = UIImage(data: imageData) else {
                call.reject("Invalid image data")
                return
            }
            
            let compressionQuality = CGFloat(call.getFloat("compressionQuality") ?? 0.8)
            
            let success = LiveActivities.shared.saveImageForLiveActivities(
                image: image,
                withName: imageName,
                compressionQuality: compressionQuality
            )
            
            call.resolve([
                "success": success,
                "imageName": imageName
            ])
        }else{
            call.reject("Live Activities require iOS 16.2+")
        }
    }
    
    @objc func removeImage(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            guard let imageName = call.getString("name") else {
                call.reject("Missing image name")
                return
            }
            
            let success = LiveActivities.shared.removeImageFromLiveActivities(withName: imageName)
            
            call.resolve([
                "success": success
            ])
        }else{
            call.reject("Unsupported")
        }
    }
    
    @objc func listImages(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            let images = LiveActivities.shared.listSavedImages()
            
            call.resolve([
                "images": images
            ])
        }else{
            call.reject("Unsupported")
        }
    }
    
    @objc func cleanupImages(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            LiveActivities.shared.cleanupOldImages()
        }
        call.resolve()
    }
    
    // MARK: - Compression
    
    private func compressLayoutJSON(_ jsonString: String) -> String? {
        guard let inputData = jsonString.data(using: .utf8) else { return nil }
        
        let bufferSize = inputData.count + 1024 // Extra space for compression overhead
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destinationBuffer.deallocate() }
        
        let compressedSize = compression_encode_buffer(
            destinationBuffer, bufferSize,
            inputData.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }, inputData.count,
            nil, COMPRESSION_ZLIB
        )
        
        guard compressedSize > 0 else { return nil }
        
        let compressedData = Data(bytes: destinationBuffer, count: compressedSize)
        let base64String = compressedData.base64EncodedString()
        
        print("📊 Compression: \(inputData.count) bytes -> \(compressedSize) bytes -> \(base64String.count) base64 chars")
        
        // Return with compression marker
        return "__COMPRESSED__:\(base64String)"
    }
    
}
