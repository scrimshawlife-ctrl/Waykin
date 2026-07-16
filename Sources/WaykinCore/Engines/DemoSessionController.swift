import Foundation

@MainActor
@Observable
public final class DemoSessionController {
    public let movementEngine: MovementEngine
    public private(set) var currentScenario: DemoScenario?
    public private(set) var isRunning = false
    public private(set) var isPaused = false
    public private(set) var tickIndex = 0
    public private(set) var presentationState = MapPresentationState(userCoordinate: nil, route: [], entities: [], statusText: "")
    
    private let scenarios: [DemoScenario] = [
        DemoScenario(
            id: .calmDayWalk,
            activity: .walk,
            experienceID: "companion_walk",
            timeContext: .midday,
            ticks: Array(repeating: (delta: 8.0, speed: 1.4), count: 12),
            expectedOutcome: "COMPLETED"
        ),
        DemoScenario(
            id: .nightOrcPursuit,
            activity: .walk,
            experienceID: "orc_pursuit",
            timeContext: .night,
            ticks: [
                (8, 2.8), (8, 2.5), (8, 1.8), (8, 0.4), (8, 3.2),
                (8, 2.9), (8, 2.1), (8, 0.2)
            ],
            expectedOutcome: "ESCAPED"
        ),
        DemoScenario(
            id: .futureSelfInterval,
            activity: .walk,
            experienceID: "future_self",
            timeContext: .twilight,
            ticks: Array(repeating: (delta: 7.0, speed: 2.6), count: 10),
            expectedOutcome: "HELD_TARGET_PACE"
        )
    ]
    
    public init(movementEngine: MovementEngine) {
        self.movementEngine = movementEngine
    }
    
    public func availableScenarios() -> [DemoScenario] { scenarios }
    
    public func start(scenarioID: DemoScenarioID) throws {
        guard let scenario = scenarios.first(where: { $0.id == scenarioID }) else { return }
        currentScenario = scenario
        tickIndex = 0
        isRunning = true
        isPaused = false
        
        try movementEngine.startSession(activity: scenario.activity, experienceID: scenario.experienceID)
        updatePresentation()
    }
    
    public func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        try? movementEngine.pauseSession()
    }
    
    public func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        try? movementEngine.resumeSession()
    }
    
    public func advanceOneTick() {
        guard let scenario = currentScenario, isRunning, !isPaused, tickIndex < scenario.ticks.count else { return }
        let (delta, speed) = scenario.ticks[tickIndex]
        movementEngine.simulate(deltaSeconds: delta, speed: speed)
        tickIndex += 1
        updatePresentation()
    }
    
    public func runToEnd() {
        guard let scenario = currentScenario, isRunning else { return }
        while tickIndex < scenario.ticks.count {
            advanceOneTick()
        }
    }
    
    public func end() -> (session: MovementSession?, result: ExperienceResult?, summary: SessionSummary?) {
        isRunning = false
        isPaused = false
        guard let scenario = currentScenario else { return (nil, nil, nil) }
        
        let finalSession: MovementSession?
        do {
            finalSession = try movementEngine.endSession()
        } catch {
            finalSession = movementEngine.currentSession
        }
        
        guard let session = finalSession else { return (nil, nil, nil) }
        
        let exp: any WaykinExperience
        switch scenario.experienceID {
        case "orc_pursuit": exp = OrcPursuitExperience()
        case "future_self": exp = FutureSelfExperience()
        default: exp = CompanionWalkExperience()
        }
        
        let context = ExperienceContext(timeOfDay: scenario.timeContext.rawValue, activity: scenario.activity)
        let state = exp.start(context: context)
        let result = exp.finish(state: state, session: session)
        
        let summary = SessionSummary(
            id: UUID(),
            sessionID: session.id,
            activity: session.activityType,
            experience: scenario.experienceID,
            variant: scenario.timeContext.rawValue,
            duration: session.elapsedTime,
            activeTime: session.activeTime,
            distanceMeters: session.distanceMeters,
            averageSpeed: session.averageSpeedMetersPerSecond,
            outcome: result.outcome,
            bondDelta: result.bondDelta,
            memory: SessionMemory(sessionID: session.id, text: result.memoryText)
        )
        
        currentScenario = nil
        tickIndex = 0
        presentationState = MapPresentationState(userCoordinate: nil, route: [], entities: [], statusText: "Session complete")
        
        return (session, result, summary)
    }
    
    public func restart() throws {
        guard let scenario = currentScenario else { return }
        try start(scenarioID: scenario.id)
    }
    
    private func updatePresentation() {
        guard let session = movementEngine.currentSession else { return }
        
        let userCoord = session.routePoints.last.map { Coordinate(lat: $0.latitude, lon: $0.longitude) }
        let route = session.routePoints.map { Coordinate(lat: $0.latitude, lon: $0.longitude) }
        
        var entities: [MapEntity] = []
        if let last = session.routePoints.last {
            entities.append(MapEntity(id: UUID(), role: "user", coordinate: Coordinate(lat: last.latitude, lon: last.longitude), relativeDistanceMeters: nil))
        }
        
        presentationState = MapPresentationState(
            userCoordinate: userCoord,
            route: route,
            entities: entities,
            statusText: "Dist: \(Int(session.distanceMeters))m • Speed: \(String(format: "%.1f", session.currentSpeedMetersPerSecond)) m/s"
        )
    }
}
