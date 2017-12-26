//
//  _ImplicitSystemManaging.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/18/17.
//

internal protocol _ImplicitSystemManaging: _FlexibleSystemManaging where
    System._Metadata: _ImplicitSystemMetadata,
    Dispatcher == _ImplicitSystemDispatcher
{
    var _scheduleInfo: (frame: Int, time: TimeInterval)? { get set }
    
    func _schedule()
    
    func _updateScheduleMode()
    
    func _prepareForScheduleIfNeeded()
    
    func _cancelScheduleIfNeeded()
    
    func _workItem(
        for systemMetadata: System._Metadata,
        forFrame frame: Int,
        forTime time: TimeInterval,
        forDeltaTime deltaTime: TimeInterval
        ) -> (() -> Void)
    
}

extension _ImplicitSystemManaging {
    internal func schedule(
        forFrame frame: Int,
        forTime time: TimeInterval,
        forDeltaTime deltaTime: TimeInterval
        )
    {
        for (id, system) in _systemPool {
            let dispatcher = _dispatcher(for: id)
            dispatcher.dispatch(
                _workItem(
                    for: system,
                    forFrame: frame,
                    forTime: time,
                    forDeltaTime: deltaTime
                ),
                with: system.qualityOfService
            )
        }
    }
    
    internal func _schedule() {
        let now = _CurrentTime()
        switch _scheduleInfo {
        case .none:
            schedule(
                forFrame: 0,
                forTime: now,
                forDeltaTime: 0
            )
            _scheduleInfo = (0, now)
        case let .some(frame, time):
            schedule(
                forFrame: frame + 1,
                forTime: now,
                forDeltaTime: now - time
            )
            _scheduleInfo = (frame + 1, now)
        }
    }
    
    internal func _updateScheduleMode() {
        if _systemPool.isEmpty {
            _cancelScheduleIfNeeded()
        } else {
            _prepareForScheduleIfNeeded()
        }
    }
}
