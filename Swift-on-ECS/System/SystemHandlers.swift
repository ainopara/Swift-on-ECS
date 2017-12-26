//
//  SystemImpl.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/16/17.
//

// System Hierarchy
// ================
// There are several kinds of systems, which is named after their
// schedule mode.
// ```
//          +- Initialize System
//          |
//          |                   +- Command Frame System
//          |                   |
//  System -+- Implicit System -+
//          |                   |
//          |                   +- User Event System
//          |
//          +- Reactive System
// ```
//
// Schedule Mode
// =============
// Systems are scheduled implicitly or reactively.
//
// ```
// +-----------------------+---------------+-----------------------------+
// | Types of Systems      | Schedule Mode | Frequency                   |
// +-----------------------+---------------+-----------------------------+
// | Initialize Systems    | Initialize    | When initializing a manager.|
// +-----------------------+---------------+-----------------------------+
// | Command Frame Systems | Implicit      | 60Hz                        |
// +-----------------------+---------------+-----------------------------+
// | User Event Systems    | Implicit      | When user event happens.    |
// +-----------------------+---------------+-----------------------------+
// | Reactive Systems      | Reactive      | When changes done.          |
// +-----------------------+---------------+-----------------------------+
// ```
//
// Defined as Functions
// ====================
// Systems are just defined as functions - which keeps states out of the
// system as much as the Swift programming language can - a system defined
// in function can only carry states by capturing exterior variables. And
// value-oriented specialization can also be implemented with higher-order
// procedure.
//

/// `InitializeHandler` implements an initialize system.
///
public typealias InitializeHandler = (
    _ context: InitializeContext
    ) -> Void

/// `CommandFrameHandler` implements a command frame system.
///
public typealias CommandFrameHandler = (
    _ context: CommandFrameContext,
    _ detalTime: TimeInterval,
    _ time: TimeInterval,
    _ frame: Int
    ) -> Void

/// `UserEventHandler` implements a user-event system.
///
public typealias UserEventHandler = (
    _ context: UserEventContext,
    _ detalTime: TimeInterval,
    _ time: TimeInterval
    ) -> Void

/// `ReactiveHandler` implements a reactive system.
///
public typealias ReactiveHandler = (
    _ tuple: Tuple,
    _ event: GroupEvent,
    _ context: ReactiveContext
    ) -> Void
