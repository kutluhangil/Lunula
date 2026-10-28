// Spike helper for docs/qa/spikes/fullscreen.md. Run: sleep 5; swift Scripts/spikes/window-list.swift
// Prints the same four fields CGWindowListReader reads. Never reads window or owner names.
import CoreGraphics
import Foundation

let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
let list = (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]) ?? []
for e in list {
    guard let pid = e[kCGWindowOwnerPID as String] as? Int32,
        let layer = e[kCGWindowLayer as String] as? Int,
        let b = e[kCGWindowBounds as String] as? NSDictionary,
        let r = CGRect(dictionaryRepresentation: b as CFDictionary)
    else { continue }
    let on = (e[kCGWindowIsOnscreen as String] as? Bool) ?? false
    print("pid=\(pid) layer=\(layer) bounds=(\(r.origin.x), \(r.origin.y), \(r.width), \(r.height)) onscreen=\(on)")
}
