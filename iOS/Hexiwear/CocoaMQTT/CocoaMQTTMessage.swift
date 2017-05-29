//
//  CocoaMQTTMessage.swift
//  CocoaMQTT
//
//  Created by Feng Lee<feng@eqmtt.io> on 14/8/3.
//  Copyright (c) 2015 emqtt.io. All rights reserved.
//

import Foundation

/**
 * MQTT Message
 */
open class CocoaMQTTMessage {
    
    open var topic: String
    
    open var payload: [UInt8]
    
    //utf8 bytes array to string
    open var string: String? {
        get {
            return NSString(bytes: payload, length: payload.count, encoding: String.Encoding.utf8.rawValue) as String?
        }
    }
    
    var qos: CocoaMQTTQOS = .qos1
    
    var retain: Bool = false
    
    var dup: Bool = false
    
    init(topic: String, string: String, qos: CocoaMQTTQOS = .qos1, retain: Bool = false, dup: Bool = false) {
        self.topic = topic
        self.payload = [UInt8](string.utf8)
        self.qos = qos
        self.retain = retain
        self.dup = dup
    }
    
    init(topic: String, payload: [UInt8], qos: CocoaMQTTQOS = .qos1, retain: Bool = false, dup: Bool = false) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
        self.dup = dup
    }
    
}

/**
 * MQTT Will Message
 */
open class CocoaMQTTWill: CocoaMQTTMessage {
    
    public init(topic: String, message: String) {
        super.init(topic: topic, payload: message.bytesWithLength)
    }
    
}
