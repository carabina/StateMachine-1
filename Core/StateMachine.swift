//
//  StateMachine.swift
//  StateMachine
//
//  Created by Alex Rupérez on 20/1/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import Foundation

/// Models a finite state machine that has a single current state.
public class StateMachine {
    
    public typealias SubscriptionToken = UUID
    /// - Parameter previous: the state that was exited, this is nil if this is the state machine's first entered state
    /// - Parameter current: the state that is being entered next
    public typealias SubscribeClosure = (_ previous: State?, _ current: State) -> Void

    /// The current state that the state machine is in.
    /// Prior to the first called to enterState this is equal to nil.
    public private(set) var current: State?
    private let states: [State]
    private var subscriptions = [SubscriptionToken: SubscribeClosure]()

    /// Create a finite state machine.
    /// - Parameter states: the finite state machine possible states
    public init(_ states: [State]) {
        self.states = states
    }

    /// Updates the current state machine.
    /// - Parameter deltaTime: the time, in seconds, since the last frame
    public func update(_ deltaTime: TimeInterval) {
        current?.update(deltaTime)
    }

    /// Subscribes to machine state changes.
    /// - Parameter closure: subscription closure
    /// - Returns: subscription token for unsubscribe
    @discardableResult public func subscribe(_ closure: @escaping SubscribeClosure) -> SubscriptionToken {
        let subscriptionToken = UUID()
        subscriptions[subscriptionToken] = closure
        return subscriptionToken
    }

    /// Unsubscribes a subscriber to machine state changes.
    /// - Parameter token: subscription token
    public func unsubscribe(_ token: SubscriptionToken) -> Bool {
        return subscriptions.removeValue(forKey: token) != nil
    }

    /// Unsubscribes all subscribers to machine state changes.
    public func unsubscribeAll() {
        subscriptions.removeAll()
    }

    /// Returns true if the indicated class is a valid next state or if current is nil.
    /// - Parameter type: the class of the state to be tested
    public func canEnterState<S: State>(_ type: S.Type) -> Bool {
        return current == nil || current?.isValidNext(state: type) == true
    }

    /// Calls canEnterState to check if we can enter the given state and then enters that state if so.
    /// State.willExit(to:) is called on the old current state.
    /// State.didEnter(from:) is called on the new state.
    /// - Parameter type: the class of the state to switch to
    /// - Returns: true if state was entered, false otherwise
    @discardableResult public func enter<S: State>(_ type: S.Type) -> Bool {
        guard canEnterState(type), let next = state(type) else {
            return false
        }
        let previous = current
        previous?.willExit(to: next)
        current = next
        subscriptions.values.forEach { $0(previous, next) }
        next.didEnter(from: previous)
        return true
    }

    /// Gets the state of the indicated class.
    /// Returns nil if the state machine does not have this state.
    /// - Parameter forClass: the type of the state you want to get
    public func state<S: State>(_ type: S.Type) -> State? {
        return states.first { $0 is S }
    }
}
