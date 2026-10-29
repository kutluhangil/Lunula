import Foundation
import Testing

@testable import IslandServices

@Suite struct ScriptRunnerTests {
    @Test func notRunningTargetIsNeverScripted() async {
        let fake = FakeExecutor(result: .success(.none))
        let r = ScriptRunner(executor: fake, isRunning: { _ in false })
        #expect(await r.run("x", target: "com.apple.Music") == .notRunning && fake.callCount == 0)
    }

    @Test func scriptTimeoutReturnsTimedOutWithinOneSecond() async {
        let r = ScriptRunner(
            executor: FakeExecutor(result: .success(.none), delay: 3), isRunning: { _ in true },
            timeout: .milliseconds(300))
        let start = ContinuousClock.now
        #expect(await r.run("x", target: "t") == .timedOut)
        #expect(ContinuousClock.now - start < .seconds(1))
    }

    @Test func executionNeverOnMainThread() async {
        let fake = FakeExecutor(result: .success(.none))
        _ = await ScriptRunner(executor: fake, isRunning: { _ in true }).run("x", target: "t")
        #expect(fake.ranOnMainThread == false)
    }

    @Test func callsAreSerialized() async {
        let fake = FakeExecutor(result: .success(.none), delay: 0.05)
        let r = ScriptRunner(executor: fake, isRunning: { _ in true })
        await withTaskGroup(of: Void.self) { g in
            for _ in 0..<5 { g.addTask { _ = await r.run("x", target: "t") } }
        }
        #expect(fake.maxConcurrency == 1)
    }

    @Test func appleEventErrorsMapToOutcomes() {
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1743) == .permissionDenied)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1744) == .permissionNeeded)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -600) == .notRunning)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1712) == .timedOut)
    }
}
