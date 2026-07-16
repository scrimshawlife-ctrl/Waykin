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
    public private(set) var companionRuntime = CompanionRuntime()
    public private(set) var currentEvent: WorldEvent?
    public private(set) var currentAudioCue: AudioCue?
    
    private let scenarios: [DemoScenario] = [
        DemoScenario(
            id: .calmDayWalk,
            activity: .walk,
            experienceID: "companion_walk",
            timeContext: .midday,
            ticks: Array(repeating: (delta: 8.0, speed: 1.4), count: 12),
            expectedOutcome: "COMPLETED"
        )
    ]
    private var currentExperienceState: ExperienceSessionState?
    
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
        companionRuntime = CompanionRuntime()
        currentEvent = nil
        currentAudioCue = nil
        
        try movementEngine.startSession(activity: scenario.activity, experienceID: scenario.experienceID)
        let context = ExperienceContext(timeOfDay: scenario.timeContext.rawValue, activity: scenario.activity)
        currentExperienceState = CompanionWalkExperience().start(context: context)
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
        if let previousState = currentExperienceState {
            let movement = MovementSnapshot(
                timestamp: movementEngine.currentSession?.routePoints.last?.timestamp ?? Date(timeIntervalSince1970: TimeInterval(tickIndex) * delta),
                speed: speed,
                distanceDelta: max(0, speed * delta),
                isMoving: speed > 0.1
            )
            let context = ExperienceContext(timeOfDay: scenario.timeContext.rawValue, activity: scenario.activity)
            let update = CompanionWalkExperience().update(previousState: previousState, movement: movement, context: context)
            currentExperienceState = update.state
            update.companionCommands.forEach { companionRuntime.apply(command: $0) }
            if case .companionWalk(let state) = update.state.runtimeState {
                currentEvent = state.lastEvent
                currentAudioCue = state.activeAudioCues.first
            }
            companionRuntime.apply(event: currentEvent)
        }
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
        
        let exp = CompanionWalkExperience()
        let context = ExperienceContext(timeOfDay: scenario.timeContext.rawValue, activity: scenario.activity)
        let state = currentExperienceState ?? exp.start(context: context)
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
        currentExperienceState = nil
        tickIndex = 0
        currentEvent = nil
        currentAudioCue = nil
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
            statusText: "Dist: \(Int(session.distanceMeters))m - Speed: \(String(format: "%.1f", session.currentSpeedMetersPerSecond)) m/s - Lira: \(companionRuntime.state.rawValue)"
        )
    }
}
