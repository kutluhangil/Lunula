import Foundation
import IslandCore
import IslandCoreTestSupport
import IslandDesign
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct IslandV25CraftTests {
    @Test(arguments: IslandVisualStyle.allCases)
    func expandedNowPlayingRendersAcrossVisualStyles(_ style: IslandVisualStyle) throws {
        let now = Date(timeIntervalSinceReferenceDate: 100_000)
        let track = NowPlayingSnapshot.fixture(
            duration: 210,
            position: 64,
            positionTimestamp: now,
            isPlaying: true,
            soundVolume: 80
        )
        let meeting = EventSnapshot.fixture(
            eventID: "evt-1",
            title: "Architecture Sync",
            start: now.addingTimeInterval(900),
            end: now.addingTimeInterval(2700),
            meetingLink: MeetingLink(service: .zoom, url: URL(string: "https://zoom.us/j/123")!)
        )
        let secondEvent = EventSnapshot.fixture(
            eventID: "evt-2",
            title: "Design Critique",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(5400)
        )

        var state = IslandState()
        state.phase = .expanded(.home)
        state.layout = IslandLayout(
            primary: Activity(
                id: "now-playing",
                priority: .normal,
                startedAt: now,
                updatedAt: now,
                expiresAt: nil,
                content: .nowPlaying(track),
                accent: RGBAColor(red: 0.92, green: 0.45, blue: 0.18, alpha: 1.0)
            ),
            detached: [],
            overflowCount: 0
        )

        let calendar = CalendarActions(
            join: { _ in },
            requestAccess: {},
            nextEvent: { meeting },
            upcomingToday: { [meeting, secondEvent] },
            allDayToday: { [] }
        )
        let tools = QuickToolsActions(
            visualStyle: { style },
            audioSpectrumBands: { [0.4, 0.7, 0.85, 0.6, 0.5, 0.75, 0.45, 0.3] },
            liveAudioSpectrumEnabled: { true }
        )
        let home = HomeInputs(
            pendingPermission: nil,
            hasNowPlaying: true,
            hasImminentMeeting: false,
            hasRunningTimer: false,
            hasWeather: true,
            hasUpcomingEvent: true,
            calendarAccessUndetermined: false
        )

        let surface = IslandSurface(
            state: state,
            notch: IslandRootView.previewNotch,
            home: home,
            now: now,
            send: { _ in },
            openSettings: {}
        )
        .environment(\.calendarActions, calendar)
        .environment(\.quickTools, tools)
        .frame(width: 760, height: 300)

        let image = try #require(ImageRenderer(content: surface).cgImage)
        #expect(PixelProbe.hasOpaqueContent(image))
    }

    @Test(arguments: IslandVisualStyle.allCases)
    func peekNowPlayingRendersAcrossVisualStyles(_ style: IslandVisualStyle) throws {
        let now = Date(timeIntervalSinceReferenceDate: 100_000)
        let track = NowPlayingSnapshot.fixture(
            duration: 185,
            position: 42,
            positionTimestamp: now,
            isPlaying: true
        )
        var state = IslandState()
        state.phase = .peek
        state.layout = IslandLayout(
            primary: Activity(
                id: "now-playing",
                priority: .normal,
                startedAt: now,
                updatedAt: now,
                expiresAt: nil,
                content: .nowPlaying(track),
                accent: RGBAColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1.0)
            ),
            detached: [],
            overflowCount: 0
        )
        let tools = QuickToolsActions(
            visualStyle: { style },
            audioSpectrumBands: { [0.35, 0.65, 0.8, 0.55, 0.7, 0.4, 0.5, 0.25] }
        )
        let home = HomeInputs(
            pendingPermission: nil,
            hasNowPlaying: true,
            hasImminentMeeting: false,
            hasRunningTimer: false,
            hasWeather: false,
            hasUpcomingEvent: false,
            calendarAccessUndetermined: false
        )

        let surface = IslandSurface(
            state: state,
            notch: IslandRootView.previewNotch,
            home: home,
            now: now,
            send: { _ in },
            openSettings: {}
        )
        .environment(\.quickTools, tools)
        .frame(width: 760, height: 300)

        let image = try #require(ImageRenderer(content: surface).cgImage)
        #expect(PixelProbe.hasOpaqueContent(image))
    }

    @Test func liquidGlassSurfaceWithDetachedBubbleAndExpandedToolsRenders() throws {
        let now = Date(timeIntervalSinceReferenceDate: 200_000)
        let track = NowPlayingSnapshot.fixture(isPlaying: true)
        let timer = TimerSnapshot(
            timerID: "timer-1",
            label: "Deep Work",
            phase: .focus,
            duration: 1500,
            endsAt: now.addingTimeInterval(900),
            pausedRemaining: nil,
            cycle: 2,
            totalCycles: 4
        )
        let layout = IslandLayout(
            primary: Activity(
                id: "now-playing",
                priority: .normal,
                startedAt: now,
                updatedAt: now,
                expiresAt: nil,
                content: .nowPlaying(track),
                accent: nil
            ),
            detached: [
                Activity(
                    id: "timer-1",
                    priority: .normal,
                    startedAt: now,
                    updatedAt: now,
                    expiresAt: nil,
                    content: .timer(timer),
                    accent: nil
                )
            ],
            overflowCount: 0
        )

        let tools = QuickToolsActions(
            timerMascot: { .flame },
            enabledQuickTools: { QuickToolID.defaultOrder },
            visualStyle: { .lunula },
            surfaceMaterial: { .liquidGlass },
            waterDropletEffect: { true },
            dropletTension: { DropletTension(pullX: 2.2, pullY: 1.8, focusX: 0.58, intensity: 0.75) },
            isScreenRecording: { true },
            dropletSensitivity: { .expressive },
            recordingStartedAt: { now.addingTimeInterval(-35) }
        )
        let home = HomeInputs(
            pendingPermission: nil,
            hasNowPlaying: true,
            hasImminentMeeting: false,
            hasRunningTimer: true,
            hasWeather: false,
            hasUpcomingEvent: false,
            calendarAccessUndetermined: false
        )

        for phase in [IslandPhase.compact, .expanded(.tools)] {
            var state = IslandState()
            state.phase = phase
            state.layout = layout
            let surface = IslandSurface(
                state: state,
                notch: IslandRootView.previewNotch,
                home: home,
                now: now,
                send: { _ in },
                openSettings: {}
            )
            .environment(\.quickTools, tools)
            .frame(width: 760, height: 300)

            let image = try #require(ImageRenderer(content: surface).cgImage)
            #expect(PixelProbe.hasOpaqueContent(image))
        }
    }

    @Test(arguments: TimerMascot.allCases)
    func timerMascotsRenderWithMorphNamespace(_ mascot: TimerMascot) throws {
        let now = Date(timeIntervalSinceReferenceDate: 300_000)
        let timer = TimerSnapshot(
            timerID: "timer-mascot",
            label: "Sprint",
            phase: .focus,
            duration: 1500,
            endsAt: now.addingTimeInterval(1200),
            pausedRemaining: nil,
            cycle: 1,
            totalCycles: 4
        )
        let layout = IslandLayout(
            primary: Activity(
                id: "timer-mascot",
                priority: .normal,
                startedAt: now,
                updatedAt: now,
                expiresAt: nil,
                content: .timer(timer),
                accent: nil
            ),
            detached: [],
            overflowCount: 0
        )
        let tools = QuickToolsActions(timerMascot: { mascot })
        let home = HomeInputs(
            pendingPermission: nil,
            hasNowPlaying: false,
            hasImminentMeeting: false,
            hasRunningTimer: true,
            hasWeather: false,
            hasUpcomingEvent: false,
            calendarAccessUndetermined: false
        )

        for phase in [IslandPhase.compact, .expanded(.home)] {
            var state = IslandState()
            state.phase = phase
            state.layout = layout
            let view = IslandSurface(
                state: state,
                notch: IslandRootView.previewNotch,
                home: home,
                now: now,
                send: { _ in },
                openSettings: {}
            )
            .environment(\.quickTools, tools)
            .frame(width: 760, height: 300)

            let image = try #require(ImageRenderer(content: view).cgImage)
            #expect(PixelProbe.hasOpaqueContent(image))
        }
    }

    @Test func quickToolsPopoversAndActionDefaultsWork() throws {
        let defaultTools = QuickToolsActions()
        #expect(defaultTools.dropletSensitivity() == .balanced)
        #expect(defaultTools.recordingStartedAt() == nil)
        #expect(defaultTools.latestClipboardText() == nil)

        var capturedCrop: (Bool, Bool)?
        var capturedPrompt: String?
        let tools = QuickToolsActions(
            surfaceMaterial: { .liquidGlass },
            quickAIMessages: {
                [
                    QuickAIMessage(role: "user", text: "Hello"),
                    QuickAIMessage(role: "assistant", text: "Streaming answer chunk"),
                ]
            },
            askQuickAI: { capturedPrompt = $0 },
            startScreenRecordingCrop: { asGIF, region in capturedCrop = (asGIF, region) },
            latestClipboardText: { "Clipboard body for quick context chips" }
        )

        tools.startScreenRecordingCrop(true, true)
        #expect(capturedCrop?.0 == true && capturedCrop?.1 == true)

        let aiView = QuickAIPopover().environment(\.quickTools, tools)
        #expect(ImageRenderer(content: aiView).cgImage != nil)
        #expect(capturedPrompt == nil)

        let mirrorView = CameraMirrorPopoverView(
            isAuthorized: false,
            isDenied: false,
            startPreview: { nil },
            stopPreview: {},
            openSystemSettings: {},
            material: .liquidGlass
        )
        #expect(ImageRenderer(content: mirrorView).cgImage != nil)

        let hubView = DetachedMenuBarHubView().environment(\.quickTools, tools)
        #expect(ImageRenderer(content: hubView).cgImage != nil)
    }

    @Test func boringNowPlayingExpandedCardRendersAtDefaultWidthWithVolumeAndAgenda() throws {
        let now = Date(timeIntervalSinceReferenceDate: 400_000)
        let track = NowPlayingSnapshot.fixture(
            title: "Midnight City (Extended Synthwave Mix)",
            artist: "M83",
            duration: 243,
            position: 92,
            positionTimestamp: now,
            isPlaying: true,
            soundVolume: 80
        )
        let firstEvent = EventSnapshot.fixture(
            eventID: "boring-evt-1",
            title: "Product Sync",
            start: now.addingTimeInterval(600),
            end: now.addingTimeInterval(2400)
        )
        let secondEvent = EventSnapshot.fixture(
            eventID: "boring-evt-2",
            title: "Design Review",
            start: now.addingTimeInterval(3600),
            end: now.addingTimeInterval(5400)
        )
        let calendar = CalendarActions(
            join: { _ in },
            requestAccess: {},
            nextEvent: { firstEvent },
            upcomingToday: { [firstEvent, secondEvent] },
            allDayToday: { [] }
        )
        let tools = QuickToolsActions(
            visualStyle: { .boring },
            audioSpectrumBands: { [0.45, 0.72, 0.88, 0.64, 0.52, 0.76, 0.48, 0.34] },
            liveAudioSpectrumEnabled: { true }
        )

        let card = NowPlayingExpandedCard(
            snapshot: track,
            accent: RGBAColor(red: 0.92, green: 0.45, blue: 0.18, alpha: 1.0)
        )
        .environment(\.calendarActions, calendar)
        .environment(\.quickTools, tools)
        .padding(.horizontal, Radii.expandedShoulder + Spacing.compactPadding)
        .frame(width: 520, height: 130)
        .background(Palette.obsidian)

        let image = try #require(ImageRenderer(content: card).cgImage)
        #expect(PixelProbe.hasOpaqueContent(image))
    }

    @Test func customCompactTrailingRendersLiveRecordingTimer() throws {
        let snapshot = CustomActivitySnapshot(
            title: "Screen Recording",
            subtitle: nil,
            symbol: "record.circle.fill",
            progress: nil,
            endsAt: nil
        )
        let tools = QuickToolsActions(
            recordingStartedAt: { Date.now.addingTimeInterval(-14) }
        )
        let view = CustomCompactTrailing(snapshot: snapshot, accent: nil)
            .environment(\.quickTools, tools)
            .frame(width: 72, height: 28)
            .background(Palette.obsidian)

        let image = try #require(ImageRenderer(content: view).cgImage)
        #expect(PixelProbe.hasOpaqueContent(image))
    }

    @Test func quickAIPopoverGeneratingStateShowsStopActionAndRenders() throws {
        var cancelled = false
        let tools = QuickToolsActions(
            surfaceMaterial: { .liquidGlass },
            quickAIMessages: {
                [
                    QuickAIMessage(role: "user", text: "Summarize release notes"),
                    QuickAIMessage(role: "assistant", text: "Streaming response…"),
                ]
            },
            isQuickAIGenerating: { true },
            cancelQuickAI: { cancelled = true }
        )

        tools.cancelQuickAI()
        #expect(cancelled)

        let view = QuickAIPopover().environment(\.quickTools, tools)
        let image = try #require(ImageRenderer(content: view).cgImage)
        #expect(PixelProbe.hasOpaqueContent(image))
    }
}
