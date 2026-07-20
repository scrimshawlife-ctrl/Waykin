import Foundation
import OSLog

/// Structured operator logging (D4). Categories are filterable in Console.app.
/// Does not claim device quality; logs software-stage signals only.
enum WaykinLog {
    static let subsystem = "life.scrimshaw.waykin"

    static let movement = Logger(subsystem: subsystem, category: "movement")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let ar = Logger(subsystem: subsystem, category: "ar")
    static let path = Logger(subsystem: subsystem, category: "path")
    static let receipt = Logger(subsystem: subsystem, category: "receipt")
}
