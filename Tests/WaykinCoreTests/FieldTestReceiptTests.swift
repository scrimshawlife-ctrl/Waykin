import XCTest
@testable import WaykinCore

final class FieldTestReceiptTests: XCTestCase {
    private let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
    private let receiptID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let sessionID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    func testSchemaRoundTripAndStableEnumEncoding() throws {
        let receipt = completedReceipt()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(receipt)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertEqual(try decoder.decode(FieldTestReceipt.self, from: data), receipt)
        XCTAssertEqual(receipt.schemaVersion, FieldTestReceipt.currentSchemaVersion)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"mode\":\"demo\""))
        XCTAssertTrue(json.contains("\"outcome\":\"completed\""))
        XCTAssertTrue(json.contains("\"persistence\":\"succeeded\""))
    }

    func testPathAndActivitySummaryFieldsRoundTripWithoutCoordinates() throws {
        let builder = makeBuilder()
        let path = PathProgressSnapshot(
            metersAlongPath: 42.5,
            relation: .onPath,
            integrityPressure: 0.12,
            acceptedSampleCount: 17,
            rejectedStreak: 0,
            isDemo: true
        )
        let enrichment = ActivityEnrichment(
            stepCadenceBand: .moderate,
            stepCountWindow: 900,
            walkingDistanceMetersWindow: 1_200,
            authorizationDenied: false
        )
        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20),
            pathProgress: path,
            activityEnrichment: enrichment
        )

        XCTAssertEqual(receipt.summary.pathRelation, PathRelation.onPath.rawValue)
        XCTAssertEqual(receipt.summary.pathMetersAlongPath, 42.5, accuracy: 0.001)
        XCTAssertEqual(receipt.summary.pathIntegrityPressure, 0.12, accuracy: 0.001)
        XCTAssertEqual(receipt.summary.pathAcceptedSampleCount, 17)
        XCTAssertEqual(receipt.summary.activityStepCadenceBand, StepCadenceBand.moderate.rawValue)
        XCTAssertFalse(receipt.summary.activityAuthorizationDenied)

        let data = try JSONEncoder().encode(receipt)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        XCTAssertTrue(json.contains("pathrelation"))
        XCTAssertTrue(json.contains("activitystepcadenceband"))
        // Must not persist raw step windows or coordinates.
        XCTAssertFalse(json.contains("stepcountwindow"))
        XCTAssertFalse(json.contains("latitude"))
        XCTAssertFalse(json.contains("longitude"))

        let decoded = try JSONDecoder().decode(FieldTestReceipt.self, from: data)
        XCTAssertEqual(decoded.summary.pathRelation, receipt.summary.pathRelation)
        XCTAssertEqual(decoded.summary.activityStepCadenceBand, receipt.summary.activityStepCadenceBand)
    }

    func testARPresentationSummaryRoundTripWithoutCoordinatesOrPaths() throws {
        let builder = makeBuilder()
        let ar = FieldTestARPresentationSummary(
            arSessionOpened: true,
            finalLODDescription: "artist_usdz:Lira_AR_Base",
            meshEvidenceClass: "ARTIST_BLEND_HERO_DCC_MID_LOD",
            finalContinuityNote: "planted_camera:replant_missing+camera_fallback",
            finalCapabilityState: "tracking",
            motionDiagnosticsLine: "dcc:idle hybrid",
            sessionStillDiagnosticLabel: "still:catalog",
            placementDeferredCount: 2,
            continuityReplantCount: 3,
            entityReplacementCount: 1,
            companionPlaced: true
        )
        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20),
            arPresentation: ar
        )
        XCTAssertEqual(receipt.schemaVersion, 4)
        XCTAssertTrue(receipt.summary.arPresentation.arSessionOpened)
        XCTAssertEqual(receipt.summary.arPresentation.continuityReplantCount, 3)
        XCTAssertEqual(receipt.summary.arPresentation.finalLODDescription, "artist_usdz:Lira_AR_Base")

        let data = try JSONEncoder().encode(receipt)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        XCTAssertTrue(json.contains("arpresentation"))
        XCTAssertTrue(json.contains("continuityreplantcount"))
        XCTAssertFalse(json.contains("latitude"))
        XCTAssertFalse(json.contains("/private/"))
        XCTAssertFalse(json.contains("clerror"))

        let decoded = try JSONDecoder().decode(FieldTestReceipt.self, from: data)
        XCTAssertEqual(decoded.summary.arPresentation, receipt.summary.arPresentation)
    }

    func testLegacySchema3WithoutARPresentationDecodesEmpty() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: try encoder.encode(completedReceipt()),
            options: []
        ) as? [String: Any])
        object["schemaVersion"] = 3
        var summary = try XCTUnwrap(object["summary"] as? [String: Any])
        summary.removeValue(forKey: "arPresentation")
        object["summary"] = summary
        let legacyData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FieldTestReceipt.self, from: legacyData)
        XCTAssertEqual(decoded.summary.arPresentation, .empty)
        XCTAssertFalse(decoded.summary.arPresentation.arSessionOpened)
    }

    func testARLabelSanitizesAbsolutePaths() {
        let ar = FieldTestARPresentationSummary(
            finalLODDescription: "/private/var/containers/Lira_AR_Base.usdz"
        )
        XCTAssertEqual(ar.finalLODDescription, "Lira_AR_Base.usdz")
    }

    func testLegacyReceiptWithoutPathFieldsDecodesWithDefaults() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: try encoder.encode(completedReceipt()),
            options: []
        ) as? [String: Any])
        object["schemaVersion"] = 2
        var summary = try XCTUnwrap(object["summary"] as? [String: Any])
        for key in [
            "pathRelation", "pathMetersAlongPath", "pathIntegrityPressure",
            "pathAcceptedSampleCount", "activityStepCadenceBand", "activityAuthorizationDenied"
        ] {
            summary.removeValue(forKey: key)
        }
        object["summary"] = summary
        let legacyData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FieldTestReceipt.self, from: legacyData)
        XCTAssertNil(decoded.summary.pathRelation)
        XCTAssertEqual(decoded.summary.pathMetersAlongPath, 0)
        XCTAssertEqual(decoded.summary.pathAcceptedSampleCount, 0)
        XCTAssertFalse(decoded.summary.activityAuthorizationDenied)
    }

    func testSchema1ReceiptDecodesWithEmptyAudioDiagnosticDefaults() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: try encoder.encode(completedReceipt()),
            options: []
        ) as? [String: Any])
        object["schemaVersion"] = 1

        var summary = try XCTUnwrap(object["summary"] as? [String: Any])
        summary.removeValue(forKey: "audioDiagnostics")
        object["summary"] = summary

        let audioDiagnosticKeys = [
            "audioDiagnosticKind",
            "audioCueKind",
            "audioDiagnosticReasonCode",
            "audioDiagnosticChannel",
            "audioRouteCategory",
            "audioRouteChangeReason",
            "audioInterruptionResumeDisposition",
            "audioSessionPolicy"
        ]
        var timeline = try XCTUnwrap(object["timeline"] as? [[String: Any]])
        timeline = timeline.map { entry in
            var mutableEntry = entry
            for key in audioDiagnosticKeys {
                mutableEntry.removeValue(forKey: key)
            }
            return mutableEntry
        }
        object["timeline"] = timeline

        let legacyData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(FieldTestReceipt.self, from: legacyData)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.summary.audioDiagnostics, FieldTestAudioDiagnosticSummary())
        XCTAssertEqual(decoded.timeline.first?.audioDiagnosticKind, nil)
        XCTAssertEqual(decoded.timeline.first?.audioRouteCategory, nil)
    }

    func testSerializedReceiptContainsNoProhibitedPrivateData() throws {
        let data = try JSONEncoder().encode(completedReceipt())
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        let prohibitedTerms = [
            "latitude", "longitude", "altitude", "coordinate", "cllocation",
            "routepoints", "address", "street", "landmark", "personaltext"
        ]

        for term in prohibitedTerms {
            XCTAssertFalse(json.contains(term), "Receipt unexpectedly contains \(term)")
        }
    }

    func testSerializedAudioDiagnosticsContainNoProhibitedKeysOrValues() throws {
        let builder = makeBuilder()
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(3),
            kind: .routeChanged,
            channel: .ambient,
            reasonCode: .interruption,
            routeCategory: .bluetooth,
            routeChangeReason: .newDeviceAvailable,
            interruptionResumeDisposition: .shouldResume,
            sessionPolicy: .ambientMixWithOthers
        ))
        let data = try JSONEncoder().encode(builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20)
        ))
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        let prohibitedKeys = [
            "\"assetpath\"",
            "\"rawerror\"",
            "\"portname\"",
            "\"devicename\"",
            "\"accessoryname\"",
            "\"routeidentifier\"",
            "\"accessoryidentifier\"",
            "\"volume\""
        ]
        let prohibitedValues = [
            "/system/library/sounds/companion-near.wav",
            "airpods pro",
            "beats studio pro",
            "carplay",
            "kitchen speaker",
            "left bud",
            "0.75",
            "39.7392,-104.9903"
        ]

        for key in prohibitedKeys {
            XCTAssertFalse(json.contains(key), "Receipt unexpectedly contains \(key)")
        }
        for value in prohibitedValues {
            XCTAssertFalse(json.contains(value), "Receipt unexpectedly contains \(value)")
        }
    }

    func testAggregationCountsMovementEventsAudioDiagnosticsAndBond() throws {
        let builder = makeBuilder()
        builder.recordMovement(diagnostic(.accepted, speed: 1.2, accumulated: true))
        builder.recordMovement(diagnostic(.awaitingFreshAnchor))
        builder.recordMovement(diagnostic(.rejectedAccuracy))
        builder.recordMovement(diagnostic(.rejectedAccuracy))
        builder.recordMovement(diagnostic(.rejectedDuplicate))
        builder.recordWorldEvent(event(.companionDrawsNear, offset: 3))
        builder.recordWorldEvent(event(.companionDrawsNear, offset: 3))
        builder.recordAudioCue(cue(.companionNear), at: startedAt.addingTimeInterval(3))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(4),
            kind: .cueReceived,
            cueKind: .companionNear,
            channel: .ambient,
            priority: 1
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(5),
            kind: .plannerAccepted,
            cueKind: .companionNear,
            channel: .ambient,
            priority: 1
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(6),
            kind: .plannerSuppressed,
            cueKind: .quietShift,
            channel: .ambient,
            priority: 1,
            reasonCode: .duplicateCue
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(7),
            kind: .assetLookupStarted,
            cueKind: .companionNear
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(8),
            kind: .assetResolved,
            cueKind: .companionNear
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(9),
            kind: .audioSessionConfigurationStarted,
            routeCategory: .builtInSpeaker,
            sessionPolicy: .ambientMixWithOthers
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(10),
            kind: .audioSessionConfigured,
            routeCategory: .builtInSpeaker,
            sessionPolicy: .ambientMixWithOthers
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(11),
            kind: .playerInitialized,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(12),
            kind: .playbackRequested,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(13),
            kind: .playRequestAccepted,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(14),
            kind: .playerObservedActive,
            channel: .ambient,
            routeCategory: .bluetooth
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(15),
            kind: .playbackInterrupted,
            channel: .ambient,
            reasonCode: .interruption,
            routeCategory: .bluetooth,
            interruptionResumeDisposition: .shouldResume
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(16),
            kind: .playbackInterruptionEnded,
            channel: .ambient,
            routeCategory: .bluetooth,
            interruptionResumeDisposition: .shouldResume
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(17),
            kind: .routeChanged,
            routeCategory: .bluetooth,
            routeChangeReason: .newDeviceAvailable
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(18),
            kind: .playbackFadeRequested,
            channel: .ambient,
            routeCategory: .bluetooth
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(18.5),
            kind: .playbackStopRequested,
            channel: .ambient,
            routeCategory: .bluetooth
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(19),
            kind: .playbackStopped,
            channel: .ambient,
            routeCategory: .bluetooth
        ))
        builder.recordInterruption("began", at: startedAt.addingTimeInterval(19))
        builder.recordLifecycle("background", at: startedAt.addingTimeInterval(19))
        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 14,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.acceptedSampleCount, 2)
        XCTAssertEqual(receipt.summary.rejectedSampleCount, 3)
        XCTAssertEqual(receipt.summary.rejectionCounts[MovementSampleDisposition.rejectedAccuracy.rawValue], 2)
        XCTAssertEqual(receipt.summary.rejectionCounts[MovementSampleDisposition.rejectedDuplicate.rawValue], 1)
        XCTAssertEqual(receipt.summary.freshAnchorResetCount, 1)
        XCTAssertEqual(receipt.summary.worldEventCounts[WorldEventKind.companionDrawsNear.rawValue], 1)
        XCTAssertEqual(receipt.summary.semanticAudioCueCounts[AudioCueKind.companionNear.rawValue], 1)
        XCTAssertEqual(receipt.summary.audioSuppressionCount, 1)
        XCTAssertEqual(receipt.summary.interruptionCount, 1)
        XCTAssertEqual(receipt.summary.lifecycleTransitionCount, 1)
        XCTAssertEqual(receipt.summary.audioDiagnostics.cueReceiptCounts[AudioCueKind.companionNear.rawValue], 1)
        XCTAssertEqual(receipt.summary.audioDiagnostics.plannerAcceptedCueCounts[AudioCueKind.companionNear.rawValue], 1)
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.suppressionReasonCounts[AudioPlaybackReasonCode.duplicateCue.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.assetLifecycleCounts[AudioPlaybackDiagnosticKind.assetLookupStarted.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.assetLifecycleCounts[AudioPlaybackDiagnosticKind.assetResolved.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.audioSessionLifecycleCounts[
                AudioPlaybackDiagnosticKind.audioSessionConfigurationStarted.rawValue
            ],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.audioSessionLifecycleCounts[
                AudioPlaybackDiagnosticKind.audioSessionConfigured.rawValue
            ],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.playerLifecycleCounts[AudioPlaybackDiagnosticKind.playerInitialized.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.playbackLifecycleCounts[AudioPlaybackDiagnosticKind.playbackRequested.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.playbackLifecycleCounts[AudioPlaybackDiagnosticKind.playRequestAccepted.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.playbackLifecycleCounts[AudioPlaybackDiagnosticKind.playerObservedActive.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.interruptionEventCounts[AudioPlaybackDiagnosticKind.playbackInterrupted.rawValue],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.interruptionEventCounts[
                AudioPlaybackDiagnosticKind.playbackInterruptionEnded.rawValue
            ],
            1
        )
        XCTAssertEqual(
            receipt.summary.audioDiagnostics.routeChangeReasonCounts[
                AudioRouteChangeReasonCode.newDeviceAvailable.rawValue
            ],
            1
        )
        XCTAssertEqual(receipt.summary.audioDiagnostics.stopCount, 1)
        XCTAssertEqual(receipt.summary.audioDiagnostics.fadeCount, 1)
        XCTAssertEqual(receipt.summary.audioDiagnostics.lastRouteCategory, .bluetooth)
        XCTAssertEqual(receipt.summary.bondDelta, 2)
        XCTAssertTrue(receipt.summary.memoryWritten)
        let routeEntry = try XCTUnwrap(receipt.timeline.first {
            $0.category == .audioDiagnostic && $0.audioDiagnosticKind == .routeChanged
        })
        XCTAssertEqual(routeEntry.audioRouteCategory, .bluetooth)
        XCTAssertEqual(routeEntry.audioRouteChangeReason, .newDeviceAvailable)
    }

    func testDurationDistanceAndSpeedSummaryRemainFinite() {
        let builder = makeBuilder()
        builder.recordMovementSnapshot(MovementSnapshot(timestamp: startedAt, speed: 1.2, distanceDelta: 2, isMoving: true))
        builder.recordMovementSnapshot(MovementSnapshot(timestamp: startedAt, speed: 1.8, distanceDelta: 3, isMoving: true))
        var invalidSession = session()
        invalidSession.elapsedTime = .infinity
        invalidSession.activeTime = .nan
        invalidSession.distanceMeters = -.infinity
        let receipt = builder.finish(
            session: invalidSession,
            outcome: .completed,
            endingBond: 12,
            memoryWritten: false,
            persistence: .notAttempted,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.durationSeconds, 0)
        XCTAssertEqual(receipt.summary.activeDurationSeconds, 0)
        XCTAssertEqual(receipt.summary.accumulatedDistanceMeters, 0)
        XCTAssertEqual(receipt.summary.maximumStabilizedSpeedMetersPerSecond, 1.8)
        XCTAssertEqual(receipt.summary.averageStabilizedSpeedMetersPerSecond, 1.5, accuracy: 0.001)
    }

    func testPauseDurationAndTimelineOrderAreStable() {
        let builder = makeBuilder()
        builder.recordSessionTransition(from: .active, to: .paused, at: startedAt.addingTimeInterval(5))
        builder.recordSessionTransition(from: .paused, to: .active, at: startedAt.addingTimeInterval(9))
        builder.recordWorldEvent(event(.quietInterval, offset: 10))
        builder.recordAudioCue(cue(.quietShift), at: startedAt.addingTimeInterval(10))
        let receipt = builder.finish(
            session: session(),
            outcome: .userEnded,
            endingBond: 12,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.pausedDurationSeconds, 4)
        XCTAssertEqual(receipt.timeline.map(\.category).prefix(4), [
            .sessionStateTransition, .sessionStateTransition, .worldEventEmitted, .audioCueRequested
        ])
    }

    func testAcceptedSamplesDoNotCreateUnboundedTimeline() {
        let builder = makeBuilder()
        for index in 0..<1_000 {
            builder.recordMovement(diagnostic(.accepted, offset: TimeInterval(index), speed: 1.1, accumulated: true))
        }
        for index in 0..<500 {
            builder.recordMovement(diagnostic(.rejectedAccuracy, offset: TimeInterval(index)))
        }

        XCTAssertEqual(builder.receipt.summary.acceptedSampleCount, 1_000)
        XCTAssertEqual(builder.receipt.summary.rejectedSampleCount, 500)
        XCTAssertEqual(builder.receipt.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)

        let finished = builder.finish(
            session: nil,
            outcome: .completed,
            endingBond: 12,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(30)
        )
        XCTAssertEqual(finished.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)
        XCTAssertEqual(finished.timeline.suffix(2).map(\.category), [.memoryWriteResult, .sessionCompleted])
    }

    func testAudioDiagnosticStopRemainsInBoundedTimeline() {
        let builder = makeBuilder()
        for index in 0..<FieldTestReceiptBuilder.maximumTimelineEntries {
            builder.recordMovement(diagnostic(.rejectedAccuracy, offset: TimeInterval(index)))
        }
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(499),
            kind: .playbackFadeRequested,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(500),
            kind: .playbackStopRequested,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))
        builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
            timestamp: startedAt.addingTimeInterval(501),
            kind: .playbackStopped,
            channel: .ambient,
            routeCategory: .builtInSpeaker
        ))

        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(600)
        )

        XCTAssertEqual(receipt.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)
        XCTAssertEqual(receipt.timeline.suffix(5).map(\.category), [
            .audioDiagnostic,
            .audioDiagnostic,
            .audioDiagnostic,
            .memoryWriteResult,
            .sessionCompleted
        ])
        XCTAssertEqual(receipt.timeline[receipt.timeline.count - 5].audioDiagnosticKind, .playbackFadeRequested)
        XCTAssertEqual(receipt.timeline[receipt.timeline.count - 4].audioDiagnosticKind, .playbackStopRequested)
        XCTAssertEqual(receipt.timeline[receipt.timeline.count - 3].audioDiagnosticKind, .playbackStopped)
        XCTAssertEqual(receipt.summary.audioDiagnostics.stopCount, 1)
        XCTAssertEqual(receipt.summary.audioDiagnostics.fadeCount, 1)
    }

    func testAudioDiagnosticTimelineIsSparseButSummaryCountsEveryEvent() {
        let builder = makeBuilder()
        for index in 0..<20 {
            builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
                timestamp: startedAt.addingTimeInterval(TimeInterval(index)),
                kind: .cueReceived,
                cueKind: .companionNear
            ))
            builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
                timestamp: startedAt.addingTimeInterval(TimeInterval(index) + 0.1),
                kind: .plannerSuppressed,
                cueKind: .companionNear,
                reasonCode: .duplicateCue
            ))
            builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
                timestamp: startedAt.addingTimeInterval(TimeInterval(index) + 0.2),
                kind: .playbackInterrupted,
                reasonCode: .interruption
            ))
            builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
                timestamp: startedAt.addingTimeInterval(TimeInterval(index) + 0.3),
                kind: .routeChanged,
                routeChangeReason: .newDeviceAvailable
            ))
        }

        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(600)
        )

        XCTAssertEqual(receipt.summary.audioDiagnostics.cueReceiptCounts[AudioCueKind.companionNear.rawValue], 20)
        XCTAssertEqual(receipt.summary.audioDiagnostics.suppressionReasonCounts[AudioPlaybackReasonCode.duplicateCue.rawValue], 20)
        XCTAssertEqual(receipt.summary.audioDiagnostics.interruptionEventCounts[AudioPlaybackDiagnosticKind.playbackInterrupted.rawValue], 20)
        XCTAssertEqual(receipt.summary.audioDiagnostics.routeChangeReasonCounts[AudioRouteChangeReasonCode.newDeviceAvailable.rawValue], 20)
        XCTAssertEqual(receipt.timeline.filter { $0.audioDiagnosticKind == .cueReceived }.count, 1)
        XCTAssertEqual(receipt.timeline.filter { $0.audioDiagnosticKind == .plannerSuppressed }.count, 1)
        XCTAssertEqual(receipt.timeline.filter { $0.audioDiagnosticKind == .playbackInterrupted }.count, 1)
        XCTAssertEqual(receipt.timeline.filter { $0.audioDiagnosticKind == .routeChanged }.count, 1)
        XCTAssertEqual(receipt.timeline.suffix(2).map(\.category), [.memoryWriteResult, .sessionCompleted])
    }

    func testTerminalReceiptEntriesEvictRequiredAudioWhenTimelineIsFull() {
        let builder = makeBuilder()
        for index in 0..<FieldTestReceiptBuilder.maximumTimelineEntries {
            builder.recordAudioDiagnostic(AudioPlaybackDiagnostic(
                timestamp: startedAt.addingTimeInterval(TimeInterval(index)),
                kind: .playbackStopped,
                channel: .ambient,
                routeCategory: .builtInSpeaker
            ))
        }

        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(600)
        )

        XCTAssertEqual(receipt.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)
        XCTAssertEqual(receipt.timeline.suffix(2).map(\.category), [.memoryWriteResult, .sessionCompleted])
        XCTAssertEqual(
            receipt.timeline.filter { $0.audioDiagnosticKind == .playbackStopped }.count,
            FieldTestReceiptBuilder.maximumTimelineEntries - 2
        )
    }

    func testTerminalReceiptEntriesEvictLegacyRequiredStopsWhenTimelineIsFull() {
        let builder = makeBuilder()
        for index in 0..<FieldTestReceiptBuilder.maximumTimelineEntries {
            builder.recordAudioLifecycle("stop", at: startedAt.addingTimeInterval(TimeInterval(index)))
        }

        let receipt = builder.finish(
            session: nil,
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(600)
        )

        XCTAssertEqual(receipt.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)
        XCTAssertEqual(receipt.timeline.suffix(2).map(\.category), [.memoryWriteResult, .sessionCompleted])
    }

    func testStoreWritesAtomicallyAndReadsLatest() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileFieldTestReceiptStore(directoryURL: directory)
        let older = completedReceipt(offset: 0)
        let newer = completedReceipt(offset: 60, receiptID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!)

        let url = try store.save(older)
        _ = try store.save(newer)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try store.loadLatest(), newer)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names.filter { $0.hasSuffix(".tmp") }.count, 0)
    }

    func testStoreSurfacesWriteFailure() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let fileURL = root.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: fileURL)
        let store = FileFieldTestReceiptStore(directoryURL: fileURL)

        XCTAssertThrowsError(try store.save(completedReceipt())) { error in
            XCTAssertEqual(error as? FieldTestReceiptStoreError, .createDirectoryFailed)
        }
    }

    func testRetentionKeepsTwentyNewestReceipts() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileFieldTestReceiptStore(directoryURL: directory)

        for index in 0..<22 {
            _ = try store.save(completedReceipt(
                offset: TimeInterval(index),
                receiptID: UUID()
            ))
        }

        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        XCTAssertEqual(files.count, 20)
        XCTAssertEqual(try store.loadLatest()?.startedAt, startedAt.addingTimeInterval(21))
    }

    func testReceiptRotationDoesNotTouchNormalMemories() throws {
        let memoryStore = PersistenceStore()
        let memory = SessionMemory(sessionID: UUID(), text: "Existing canonical memory")
        try memoryStore.saveMemory(memory)
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let receiptStore = FileFieldTestReceiptStore(directoryURL: directory, retentionLimit: 1)

        _ = try receiptStore.save(completedReceipt(offset: 0))
        _ = try receiptStore.save(completedReceipt(offset: 1, receiptID: UUID()))

        XCTAssertEqual(try memoryStore.memoryCount(), 1)
        XCTAssertEqual(try memoryStore.loadMemories().first?.id, memory.id)
    }

    private func makeBuilder() -> FieldTestReceiptBuilder {
        FieldTestReceiptBuilder(
            receiptID: receiptID,
            sessionID: sessionID,
            mode: .demo,
            startedAt: startedAt,
            startingBond: 12
        )
    }

    private func completedReceipt(
        offset: TimeInterval = 0,
        receiptID: UUID? = nil
    ) -> FieldTestReceipt {
        let start = startedAt.addingTimeInterval(offset)
        let builder = FieldTestReceiptBuilder(
            receiptID: receiptID ?? self.receiptID,
            sessionID: sessionID,
            mode: .demo,
            startedAt: start,
            startingBond: 12
        )
        builder.recordAudioLifecycle("stop", at: start.addingTimeInterval(20))
        return builder.finish(
            session: session(startedAt: start),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: start.addingTimeInterval(20)
        )
    }

    private func session(startedAt: Date? = nil) -> MovementSession {
        var session = MovementSession(
            id: sessionID,
            activityType: .walk,
            experienceID: "companion_walk",
            startedAt: startedAt ?? self.startedAt
        )
        session.endedAt = (startedAt ?? self.startedAt).addingTimeInterval(20)
        session.elapsedTime = 20
        session.activeTime = 16
        session.distanceMeters = 24
        session.currentSpeedMetersPerSecond = 0
        session.averageSpeedMetersPerSecond = 1.5
        session.movementState = .stopped
        return session
    }

    private func diagnostic(
        _ disposition: MovementSampleDisposition,
        offset: TimeInterval = 0,
        speed: Double = 0,
        accumulated: Bool = false
    ) -> MovementSampleDiagnostic {
        MovementSampleDiagnostic(
            timestamp: startedAt.addingTimeInterval(offset),
            disposition: disposition,
            accuracyBucket: .usable,
            derivedSpeedMetersPerSecond: speed,
            accumulatedDistance: accumulated
        )
    }

    private func event(_ kind: WorldEventKind, offset: TimeInterval) -> WorldEvent {
        WorldEvent(kind: kind, occurredAt: startedAt.addingTimeInterval(offset), intensity: 0.5, debugLabel: kind.rawValue)
    }

    private func cue(_ kind: AudioCueKind) -> AudioCue {
        AudioCue(
            kind: kind,
            intensity: 0.5,
            priority: 1,
            cooldownGroup: kind.rawValue,
            shouldFade: true,
            debugLabel: kind.rawValue
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("waykin-receipt-\(UUID().uuidString)", isDirectory: true)
    }
}
