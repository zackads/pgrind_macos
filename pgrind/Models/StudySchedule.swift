//
//  StudySchedule.swift
//  pgrind
//
//  Created by Zack Adlington on 16/05/2026.
//

import Foundation

enum StudySchedule: Codable, Hashable {
    case daily(hour: Int, minute: Int)
    case weekly(on: Weekday, hour: Int, minute: Int)

    enum Weekday: Int, Codable, CaseIterable, CustomStringConvertible {
        case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

        var description: String {
            switch self {
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            case .sunday: return "Sunday"
            }
        }
    }
}

extension StudySchedule: CustomStringConvertible {
    var description: String {
        switch self {
        case .daily(let hour, let minute):
            return "Daily at \(formattedTime(hour: hour, minute: minute))"
        case .weekly(let day, let hour, let minute):
            return "Every \(day) at \(formattedTime(hour: hour, minute: minute))"
        }
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, period)
    }
}
