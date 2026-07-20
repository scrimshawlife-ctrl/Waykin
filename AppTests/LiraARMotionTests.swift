import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class LiraARMotionTests: XCTestCase {
    func testBreathIsRestAtZeroElapsed() {
        for state in CompanionPresentationState.allCases {
            XCTAssertEqual(
                LiraARMotion.coreBreathScale(elapsed: 0, state: state),
                1,
                accuracy: 0.0001,
                "state \(state)"
            )
        }
    }

    func testBreathAndSwayAreBounded() {
        let samples: [TimeInterval] = [0, 0.25, 0.5, 1, 2, 5, 10]
        for state in CompanionPresentationState.allCases {
            for t in samples {
                let breath = LiraARMotion.coreBreathScale(elapsed: t, state: state)
                XCTAssertGreaterThan(breath, 0.85, "breath \(state) t=\(t)")
                XCTAssertLessThan(breath, 1.15, "breath \(state) t=\(t)")
                let sway = LiraARMotion.filamentSwayRadians(elapsed: t, state: state)
                XCTAssertGreaterThan(sway, -0.2, "sway \(state) t=\(t)")
                XCTAssertLessThan(sway, 0.2, "sway \(state) t=\(t)")
            }
        }
    }

    func testNonFiniteElapsedTreatedAsZero() {
        XCTAssertEqual(LiraARMotion.coreBreathScale(elapsed: .nan, state: .idle), 1, accuracy: 0.0001)
        XCTAssertEqual(LiraARMotion.coreBreathScale(elapsed: -.infinity, state: .follow), 1, accuracy: 0.0001)
        XCTAssertEqual(LiraARMotion.filamentSwayRadians(elapsed: .infinity, state: .alert), 0, accuracy: 0.0001)
    }

    func testRendererLocalMotionResetsOnClear() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        renderer.advanceLocalMotion(by: 1.5)
        XCTAssertGreaterThan(renderer.localMotionElapsed, 1.0)
        _ = renderer.clearSession()
        XCTAssertEqual(renderer.localMotionElapsed, 0, accuracy: 0.0001)
        XCTAssertEqual(renderer.spawnCoalesceElapsed, 0, accuracy: 0.0001)
    }

    func testHunterEchoOnlyInAlert() {
        XCTAssertTrue(LiraARMotion.showsHunterEcho(state: .alert))
        XCTAssertFalse(LiraARMotion.showsHunterEcho(state: .idle))
        XCTAssertFalse(LiraARMotion.showsHunterEcho(state: .follow))
        let offset = LiraARMotion.hunterEchoOffset(elapsed: 0)
        XCTAssertLessThan(offset.z, 0, "echo sits behind")
        // Rest Y includes default ground offset so echo is not planted at 0.02 world.
        XCTAssertGreaterThan(offset.y, 0.25)
        let raised = LiraARMotion.hunterEchoPosition(elapsed: 0, groundOffset: 0.1)
        XCTAssertEqual(raised.y, 0.1 + LiraARMotion.hunterEchoBaseYAboveGround, accuracy: 0.0001)
    }

    func testBodyBobUsesGroundOffsetRest() {
        let rest = LiraARMotion.bodyRestY()
        XCTAssertEqual(rest, LiraARMotion.defaultGroundOffsetMeters + LiraARMotion.bodyBaseYAboveGround, accuracy: 0.0001)
        let atZero = LiraARMotion.bodyPositionY(elapsed: 0, state: .idle)
        XCTAssertEqual(atZero, rest, accuracy: 0.0001)
        let samples: [TimeInterval] = [0.2, 0.5, 1.0, 2.5]
        for t in samples {
            let y = LiraARMotion.bodyPositionY(elapsed: t, state: .idle)
            XCTAssertGreaterThan(y, rest - 0.02)
            XCTAssertLessThan(y, rest + 0.02)
        }
    }

    func testEarTailAndFilamentSegmentsAreBounded() {
        let samples: [TimeInterval] = [0, 0.3, 1, 3]
        for state in CompanionPresentationState.allCases {
            for t in samples {
                let left = LiraARMotion.earFlutterRadians(elapsed: t, isLeft: true, state: state)
                let right = LiraARMotion.earFlutterRadians(elapsed: t, isLeft: false, state: state)
                XCTAssertLessThan(abs(left), 0.12, "left ear \(state) t=\(t)")
                XCTAssertLessThan(abs(right), 0.12, "right ear \(state) t=\(t)")
                let tail = LiraARMotion.tailSwayRadians(elapsed: t, state: state)
                XCTAssertLessThan(abs(tail), 0.2, "tail \(state) t=\(t)")
                for segment in 0..<3 {
                    let pitch = LiraARMotion.filamentSegmentPitch(elapsed: t, segmentIndex: segment, state: state)
                    XCTAssertLessThan(abs(pitch), 0.25, "filament segment \(segment) \(state) t=\(t)")
                }
            }
        }
        // Phase shift: mid and tip should not always match at t>0.
        let mid = LiraARMotion.filamentSegmentPitch(elapsed: 0.7, segmentIndex: 1, state: .follow)
        let tip = LiraARMotion.filamentSegmentPitch(elapsed: 0.7, segmentIndex: 2, state: .follow)
        XCTAssertNotEqual(mid, tip, accuracy: 0.0001)
    }

    func testFactoryIncludesMultiSegmentFilament() {
        let entity = CompanionEntityFactory().makeLira()
        let filament = entity.findEntity(named: "Filament")
        XCTAssertNotNil(filament)
        XCTAssertNotNil(filament?.findEntity(named: LiraARMotion.filamentBaseName))
        XCTAssertNotNil(filament?.findEntity(named: LiraARMotion.filamentMidName))
        XCTAssertNotNil(filament?.findEntity(named: LiraARMotion.filamentTipName))
        let body = entity.findEntity(named: "Body")
        XCTAssertNotNil(body)
        XCTAssertEqual(
            body?.position.y ?? -1,
            LiraARMotion.bodyRestY(),
            accuracy: 0.0001
        )
    }

    func testMeshPrimitivesGenerateWithoutFallbackOnlySphere() {
        // Ensure custom meshes are real MeshResources (non-nil bounds).
        let head = LiraMeshGeometry.taperedHead()
        let blade = LiraMeshGeometry.sensorBlade()
        let sphere = LiraMeshGeometry.sphere(radius: 0.1, segments: 12, rings: 8)
        let segment = LiraMeshGeometry.filamentSegment()
        XCTAssertGreaterThan(head.bounds.extents.x, 0)
        XCTAssertGreaterThan(blade.bounds.extents.y, 0)
        XCTAssertGreaterThan(sphere.bounds.extents.x, 0)
        XCTAssertGreaterThan(segment.bounds.extents.x, 0)
        // Tapered head should be elongated vs a unit-ish sphere radius 0.1
        XCTAssertGreaterThan(head.bounds.extents.z, head.bounds.extents.x * 0.5)
    }

    func testAnimationLibraryGeneratesAllClipsAndMapsStates() throws {
        for clip in LiraARAnimationLibrary.ClipID.allCases {
            let resource = try LiraARAnimationLibrary.generate(clip: clip)
            XCTAssertNotNil(resource, "clip \(clip.rawValue)")
        }
        XCTAssertEqual(LiraARAnimationLibrary.loopingClip(for: .idle), .idleBreath)
        XCTAssertEqual(LiraARAnimationLibrary.loopingClip(for: .investigate), .idleBreath)
        XCTAssertEqual(LiraARAnimationLibrary.loopingClip(for: .follow), .followSway)
        XCTAssertEqual(LiraARAnimationLibrary.loopingClip(for: .alert), .alertTension)
        XCTAssertNil(LiraARAnimationLibrary.loopingClip(for: .celebrate))
    }

    func testHeadAttentionYawIsBoundedAndInvestigateLeansLeft() {
        let investigate = LiraARMotion.headAttentionYawRadians(elapsed: 2, state: .investigate)
        let idle = LiraARMotion.headAttentionYawRadians(elapsed: 2, state: .idle)
        XCTAssertLessThan(investigate, 0, "investigate looks slightly off-axis")
        XCTAssertGreaterThan(investigate, -0.35)
        XCTAssertLessThan(abs(idle), 0.12)
        let plant = LiraARMotion.rootPlantEase(progress: 0.5)
        XCTAssertGreaterThan(plant, 0.4)
        XCTAssertLessThan(plant, 0.6)
    }

    func testSpawnCoalesceProgressAndScale() {
        XCTAssertEqual(LiraARMotion.spawnCoalesceProgress(elapsed: 0, duration: 0.7), 0, accuracy: 0.001)
        XCTAssertEqual(LiraARMotion.spawnCoalesceProgress(elapsed: 0.7, duration: 0.7), 1, accuracy: 0.001)
        XCTAssertEqual(LiraARMotion.spawnCoalesceProgress(elapsed: 2, duration: 0.7), 1, accuracy: 0.001)
        XCTAssertEqual(LiraARMotion.spawnScaleFactor(progress: 0), 0.92, accuracy: 0.001)
        XCTAssertEqual(LiraARMotion.spawnScaleFactor(progress: 1), 1.0, accuracy: 0.001)
        XCTAssertGreaterThan(LiraARMotion.spawnScaleFactor(progress: 0.5), 0.92)
        XCTAssertLessThan(LiraARMotion.spawnScaleFactor(progress: 0.5), 1.0)
    }

    func testFactoryIncludesOptionalHunterEchoNode() {
        let entity = CompanionEntityFactory().makeLira()
        let echo = entity.findEntity(named: LiraARMotion.hunterEchoNodeName)
        XCTAssertNotNil(echo)
        XCTAssertFalse(echo?.isEnabled ?? true)
    }

    func testPackagedUSDZPreloadsWithRequiredHierarchy() async {
        XCTAssertTrue(LiraARAssetCatalog.hasPackagedUSDZ)
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle()
        // If RealityKit accepts the USDZ, source flips to usdz; otherwise procedural fallback is OK.
        let entity = loader.makeLira()
        XCTAssertEqual(entity.name, CompanionEntityFactory.rootName)
        for name in CompanionEntityFactory.requiredNodeNames {
            XCTAssertNotNil(
                entity.findEntity(named: name),
                "missing \(name) after preload (source=\(loader.activeLODDescription))"
            )
        }
        if case .usdz = loader.source {
            XCTAssertTrue(loader.activeLODDescription.contains("Lira_AR_Base"))
        }
    }
}
