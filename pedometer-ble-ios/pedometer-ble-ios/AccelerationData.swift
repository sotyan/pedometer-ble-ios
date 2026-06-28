//
//  AccelerationData.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/25.
//

import Foundation

struct AccelerationData{
    let x: Float
    let y: Float
    let z: Float

    var norm: Float { (x*x + y*y + z*z).squareRoot() }

    static let zero = AccelerationData(x:0, y:0, z:0)
    
    func toData() -> Data{
        var values: [Float] = [x,y,z]
        return values.withUnsafeMutableBytes{Data($0)}
    }
    
    static func fromData(_ data: Data) -> AccelerationData? {
        guard data.count >= 12 else {return nil}
        let x = data.withUnsafeBytes{ $0.load(fromByteOffset: 0, as: Float.self)}
        let y = data.withUnsafeBytes{ $0.load(fromByteOffset: 4, as: Float.self)}
        let z = data.withUnsafeBytes{ $0.load(fromByteOffset: 8, as: Float.self)}
        return AccelerationData(x: x, y: y, z: z)
    }

    var norm: Double {
        sqrt(Double(x * x + y * y + z * z))
    }
}
