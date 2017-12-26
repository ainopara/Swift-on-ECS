//
//  _ImplicitSystemScheduler.swift
//  ECS
//
//  Created by Yu-Long Li on 12/9/17.
//

import SwiftExt
import QuartzCore
import Dispatch

internal protocol _SystemSchedulerDelegate: class {
    func _scheduleCommandFrame()
    func _scheduleLoop()
}

internal class _ImplicitSystemScheduler {
    internal unowned let delegate: _SystemSchedulerDelegate
    
    internal let _lock: ReadWriteLock
    
    internal var _queues: [SystemQoS : DispatchQueue]
    
    internal init (delegate: _SystemSchedulerDelegate) {
        self.delegate = delegate
        _lock = try! ReadWriteLock()
        _queues = [.userInteractive : DispatchQueue.main]
    }
    
    internal func _queue(for qualityOfService: SystemQoS)
        -> DispatchQueue
    {
        return _lock.waitToAcquireReadingAndPerform {
            if let queue = _queues[qualityOfService] {
                return queue
            } else {
                return _lock.waitToAcquireWritingAndPerform {
                    let queue = DispatchQueue(
                        label: qualityOfService._queueLabel,
                        qos: qualityOfService._dispatchQoS
                    )
                    _queues[qualityOfService] = queue
                    return queue
                }
            }
        }
    }
    
    deinit {
        if let displayLink = _displayLink_ {
            displayLink.invalidate()
        }
        if let runLoopObserver = _runLoopObserver_ {
            CFRunLoopObserverInvalidate(runLoopObserver)
        }
    }
    
    @objc
    internal func _commandFrameDidTick(_ sender: CADisplayLink) {
        delegate._scheduleCommandFrame()
    }
    
    private var _displayLink: CADisplayLink {
        if _displayLink_ == nil {
            _displayLink_ = CADisplayLink(target: self, selector: #selector(_commandFrameDidTick))
            _displayLink_.add(to: .main, forMode: .commonModes)
        }
        return _displayLink_
    }
    
    private var _runLoopObserver: CFRunLoopObserver {
        if _runLoopObserver_ == nil {
            let activities: CFRunLoopActivity = [.beforeWaiting, .exit]
            _runLoopObserver_ = CFRunLoopObserverCreate(
                kCFAllocatorDefault,
                activities.rawValue,
                true,
                .max,
                _SystemManagerCoreHandleMainRunLoopEvents,
                &_runLoopObserverContext
            )
            CFRunLoopAddObserver(CFRunLoopGetMain(), _runLoopObserver_, .commonModes)
        }
        return _runLoopObserver_
    }
    
    private var _runLoopObserverContext: CFRunLoopObserverContext {
        get {
            if _runLoopObserverContext_ == nil {
                _runLoopObserverContext_ = CFRunLoopObserverContext(
                    version: 0,
                    info: Unmanaged.passUnretained(self).toOpaque(),
                    retain: nil,
                    release: nil,
                    copyDescription: nil
                )
            }
            return _runLoopObserverContext_
        }
        set { _runLoopObserverContext_ = newValue }
    }
    
    private var _displayLink_: CADisplayLink!
    
    private var _runLoopObserver_: CFRunLoopObserver!
    
    private var _runLoopObserverContext_: CFRunLoopObserverContext!
}

internal func _SystemManagerCoreHandleMainRunLoopEvents(
    _ observer: CFRunLoopObserver?,
    _ activity: CFRunLoopActivity,
    _ context: UnsafeMutableRawPointer?
    )
{
    let observerContextPtr = context!.bindMemory(
        to: CFRunLoopObserverContext.self,
        capacity: 1
    )
    
    let systemManagerCore = Unmanaged<_ImplicitSystemScheduler>
        .fromOpaque(observerContextPtr[0].info)
        .takeUnretainedValue()
    
    if activity == .beforeWaiting {
        // end current run-loop -> enter next run-loop.
        systemManagerCore.delegate._scheduleLoop()
    } else if activity == .exit {
        // exit run-loop.
        systemManagerCore.delegate._scheduleLoop()
    } else {
        fatalError("Unexpected run-loop events.")
    }
}

// MARK: - Supporting Types
extension SystemQoS {
    internal var _queueLabel: String {
        return "com.WeZZard.ECS.SystemManager.DispatchQueuePool.\(debugDescription)"
    }
    
    internal var _dispatchQoS: DispatchQoS {
        switch self {
        case .userInteractive:  return .userInteractive
        case .userInitiated:    return .userInitiated
        case .utility:          return .utility
        case .background:       return .background
        }
    }
}
