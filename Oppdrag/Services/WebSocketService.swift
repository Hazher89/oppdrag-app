//
//  WebSocketService.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import Combine

class WebSocketService: NSObject, ObservableObject {
    static let shared = WebSocketService()
    
    @Published var isConnected = false
    @Published var lastMessage: ChatMessage?
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    
    // Replace with your WebSocket server URL
    private let wsURL = "wss://your-websocket-server.com/ws"
    
    private override init() {
        super.init()
        setupURLSession()
    }
    
    // MARK: - Connection Management
    func connect() {
        guard let url = URL(string: wsURL) else {
            print("Invalid WebSocket URL")
            return
        }
        
        let request = URLRequest(url: url)
        webSocket = urlSession?.webSocketTask(with: request)
        webSocket?.resume()
        
        startReceiving()
        startHeartbeat()
        
        isConnected = true
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        stopHeartbeat()
        isConnected = false
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Message Handling
    func sendMessage(_ message: ChatMessage) {
        guard isConnected else {
            print("WebSocket not connected")
            return
        }
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    print("Failed to send message: \(error)")
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    func joinConversation(_ conversationId: String) {
        let joinMessage = [
            "type": "join",
            "conversationId": conversationId
        ]
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: joinMessage)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    print("Failed to join conversation: \(error)")
                }
            }
        } catch {
            print("Failed to encode join message: \(error)")
        }
    }
    
    func leaveConversation(_ conversationId: String) {
        let leaveMessage = [
            "type": "leave",
            "conversationId": conversationId
        ]
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: leaveMessage)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    print("Failed to leave conversation: \(error)")
                }
            }
        } catch {
            print("Failed to encode leave message: \(error)")
        }
    }
    
    // MARK: - Receiving Messages
    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startReceiving() // Continue receiving
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            // Try to parse as chat message first
            if let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.lastMessage = chatMessage
                    NotificationCenter.default.post(
                        name: .newChatMessage,
                        object: nil,
                        userInfo: ["message": chatMessage]
                    )
                }
                return
            }
            
            // Try to parse as system message
            if let systemMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = systemMessage["type"] as? String {
                handleSystemMessage(type: type, data: systemMessage)
            }
        } catch {
            print("Failed to parse message: \(error)")
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary messages if needed
        print("Received binary message")
    }
    
    private func handleSystemMessage(type: String, data: [String: Any]) {
        switch type {
        case "ping":
            sendPong()
        case "pong":
            // Heartbeat response
            break
        case "error":
            if let errorMessage = data["message"] as? String {
                print("WebSocket error: \(errorMessage)")
            }
        default:
            print("Unknown system message type: \(type)")
        }
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendPing() {
        let pingMessage = ["type": "ping"]
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: pingMessage)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    print("Failed to send ping: \(error)")
                }
            }
        } catch {
            print("Failed to encode ping: \(error)")
        }
    }
    
    private func sendPong() {
        let pongMessage = ["type": "pong"]
        
        do {
            let messageData = try JSONSerialization.data(withJSONObject: pongMessage)
            let messageString = String(data: messageData, encoding: .utf8) ?? ""
            
            let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    print("Failed to send pong: \(error)")
                }
            }
        } catch {
            print("Failed to encode pong: \(error)")
        }
    }
    
    // MARK: - Reconnection
    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        // Attempt to reconnect after 5 seconds
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        print("WebSocket disconnected with code: \(closeCode)")
        handleDisconnection()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newChatMessage = Notification.Name("newChatMessage")
} 