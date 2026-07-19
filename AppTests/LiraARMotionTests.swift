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
