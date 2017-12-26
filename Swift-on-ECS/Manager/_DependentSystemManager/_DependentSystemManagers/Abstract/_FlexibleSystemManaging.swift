//
//  _FlexibleSystemManaging.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/23/17.
//

internal protocol _FlexibleSystemManaging: _DependentSystemManaging where
    System._Metadata: _FlexibleSystemMetadata
{
    func qualityOfService(forSystem system: System) -> SystemQoS
    
    func setQualityOfService(
        _ qualityOfService: SystemQoS,
        forSystem system: System
    )
}

extension _FlexibleSystemManaging {
    internal func qualityOfService(forSystem system: System)
        -> SystemQoS
    {
        precondition(system._manager === self)
        return _sync {
            _systemPool.qualityOfServiceForSystem(at: system._index)
        }
    }
    
    internal func setQualityOfService(
        _ qualityOfService: SystemQoS,
        forSystem system: System
        )
    {
        _sync {
            precondition(system._manager === self)
            _systemPool.setSystem(
                at: system._index,
                qualityOfService: qualityOfService
            )
        }
    }
}
