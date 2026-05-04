# Design Document: Real-time Order System

## Overview

This document outlines the technical design for implementing a WebSocket-based real-time order system for the FoodieGo application. The system replaces the current polling mechanism (5-second intervals) with bidirectional WebSocket connections, enabling instant order updates, kitchen notifications, push notifications, and real-time messaging between customers, kitchen staff, and waiters.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
├─────────────────────────────────────────────────────────────────┤
│  Flutter App (Customer)  │  Flutter App (Kitchen Dashboard)     │
│  - WebSocket Client      │  - WebSocket Client                  │
│  - FCM Push Receiver     │  - Sound Alert System                │
│  - Offline Queue         │  - Order Timer Display               │
└──────────────┬───────────┴──────────────┬───────────────────────┘
               │                          │
               │    WebSocket Connection  │
               │                          │
┌──────────────▼──────────────────────────▼───────────────────────┐
│                      WebSocket Server                            │
├─────────────────────────────────────────────────────────────────┤
│  Socket.IO Server (Node.js)                                     │
│  - Connection Manager                                            │
│  - Room Manager (table, kitchen, restaurant-admin)              │
│  - Event Broadcaster                                             │
│  - Authentication Middleware                                     │
│  - Heartbeat Handler                                             │
└──────────────┬──────────────────────────────────────────────────┘
               │
               │    Emit Events
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                    Business Logic Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  Order Controller                                                │
│  - createOrder() → emit "order:created"                         │
│  - updateOrderStatus() → emit "order:updated"                   │
│  - cancelOrder() → emit "order:cancelled"                       │
│  - callWaiter() → emit "waiter:called"                          │
└──────────────┬──────────────────────────────────────────────────┘
               │
               │    Database Operations
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                      Data Layer                                  │
├─────────────────────────────────────────────────────────────────┤
│  MongoDB                                                         │
│  - Order Collection                                              │
│  - Table Collection                                              │
│  - User Collection                                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  External Services                               │
├─────────────────────────────────────────────────────────────────┤
│  Firebase Cloud Messaging (FCM)                                  │
│  - Push Notification Service                                     │
│  - Device Token Management                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. Backend Components

##### 1.1 WebSocket Server (`backend/src/socket/socket.server.js`)
- **Technology**: Socket.IO v4.x
- **Responsibilities**:
  - Manage WebSocket connections
  - Handle authentication via JWT tokens
  - Manage socket rooms (table-specific, kitchen, restaurant-admin)
  - Broadcast events to appropriate rooms
  - Handle heartbeat/ping-pong for connection health
  - Implement reconnection logic

##### 1.2 Socket Manager (`backend/src/socket/socket.manager.js`)
- **Responsibilities**:
  - Provide API for emitting events from controllers
  - Abstract Socket.IO implementation details
  - Handle room subscriptions and unsubscriptions
  - Validate event payloads
  - Log socket events for debugging

##### 1.3 Socket Middleware (`backend/src/middlewares/socket.middleware.js`)
- **Responsibilities**:
  - Authenticate socket connections using JWT
  - Authorize room subscriptions based on user role
  - Rate limit socket events to prevent abuse
  - Log connection attempts and failures

##### 1.4 Enhanced Order Controller
- **Modifications**:
  - Emit socket events after order state changes
  - Integrate with Socket Manager
  - Maintain backward compatibility with REST API

##### 1.5 Push Notification Service (`backend/src/services/push-notification.service.js`)
- **Technology**: Firebase Admin SDK
- **Responsibilities**:
  - Send push notifications via FCM
  - Manage device tokens
  - Handle notification templates
  - Track notification delivery status

#### 2. Frontend Components

##### 2.1 WebSocket Service (`frontend/lib/core/services/websocket_service.dart`)
- **Technology**: socket_io_client package
- **Responsibilities**:
  - Establish and maintain WebSocket connection
  - Handle authentication with JWT token
  - Implement exponential backoff reconnection
  - Subscribe/unsubscribe from socket rooms
  - Emit and listen for events
  - Manage connection state (connected, reconnecting, disconnected)
  - Queue messages when offline

##### 2.2 WebSocket Provider (`frontend/lib/state/websocket/websocket_provider.dart`)
- **Technology**: Flutter Provider/ChangeNotifier
- **Responsibilities**:
  - Expose WebSocket connection state to UI
  - Provide methods for subscribing to events
  - Manage event listeners lifecycle
  - Notify UI of connection state changes

##### 2.3 Enhanced Order Status Page
- **Modifications**:
  - Replace polling timer with WebSocket event listeners
  - Subscribe to table-specific room on mount
  - Display real-time connection status indicator
  - Handle offline queue for "Call Waiter" actions
  - Show in-app notifications for order updates

##### 2.4 Enhanced Kitchen Orders Page
- **Modifications**:
  - Replace polling timer with WebSocket event listeners
  - Subscribe to "kitchen" room on mount
  - Play sound alerts for new orders
  - Display order timers with color coding
  - Animate order transitions between status groups
  - Show connection status indicator

##### 2.5 Push Notification Handler (`frontend/lib/core/services/notification_service.dart`)
- **Enhancements**:
  - Register device token with backend
  - Handle FCM message reception
  - Navigate to order page on notification tap
  - Suppress system notifications when app is in foreground

## Data Models

### Socket Event Payloads

#### Order Events

```typescript
// order:created
{
  eventType: "order:created",
  orderId: string,
  orderNumber: string,
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  items: Array<{
    name: string,
    quantity: number,
    price: number
  }>,
  totalPrice: number,
  status: "pending",
  timestamp: ISO8601 string,
  notes?: string
}

// order:updated
{
  eventType: "order:updated",
  orderId: string,
  orderNumber: string,
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  status: "confirmed" | "preparing" | "ready" | "completed" | "cancelled",
  timestamp: ISO8601 string,
  notification?: {
    message: string,
    type: "success" | "error" | "info" | "warning",
    timestamp: ISO8601 string
  }
}

// order:cancelled
{
  eventType: "order:cancelled",
  orderId: string,
  orderNumber: string,
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  reason: string,
  timestamp: ISO8601 string
}
```

#### Waiter Alert Events

```typescript
// waiter:called
{
  eventType: "waiter:called",
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  message: string,
  customerId?: string,
  timestamp: ISO8601 string
}
```

#### Table Status Events

```typescript
// table:occupied
{
  eventType: "table:occupied",
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  isOccupied: true,
  timestamp: ISO8601 string
}

// table:available
{
  eventType: "table:available",
  tableId: string,
  tableNumber: string,
  restaurantId: string,
  isOccupied: false,
  timestamp: ISO8601 string
}
```

#### Connection Events

```typescript
// connection:established
{
  eventType: "connection:established",
  clientId: string,
  timestamp: ISO8601 string
}
```

### Socket Rooms

#### Room Naming Convention

```
table:{tableId}              // Customer-specific room for a table session
kitchen:{restaurantId}       // Kitchen staff room for a restaurant
restaurant-admin:{restaurantId}  // Restaurant admin room for table management
```

#### Room Authorization Matrix

| User Role | table:{tableId} | kitchen:{restaurantId} | restaurant-admin:{restaurantId} |
|-----------|----------------|------------------------|--------------------------------|
| Customer (Guest) | ✅ (if has active order) | ❌ | ❌ |
| Customer (Logged In) | ✅ (if has active order) | ❌ | ❌ |
| Restaurant Staff | ✅ (if owns restaurant) | ✅ (if owns restaurant) | ✅ (if owns restaurant) |
| Admin | ✅ | ✅ | ✅ |

## API Design

### WebSocket Events (Socket.IO)

#### Client → Server Events

```typescript
// Join a room
socket.emit('join:room', {
  roomName: string,  // e.g., "table:123", "kitchen:456"
  token: string      // JWT token for authorization
})

// Leave a room
socket.emit('leave:room', {
  roomName: string
})

// Send chat message (future feature)
socket.emit('message:send', {
  orderId: string,
  message: string,
  senderRole: "user" | "driver"
})

// Update driver location (future feature)
socket.emit('location:update', {
  orderId: string,
  latitude: number,
  longitude: number
})
```

#### Server → Client Events

```typescript
// Order events
socket.on('order:created', (payload) => { /* ... */ })
socket.on('order:updated', (payload) => { /* ... */ })
socket.on('order:cancelled', (payload) => { /* ... */ })

// Waiter alerts
socket.on('waiter:called', (payload) => { /* ... */ })

// Table status
socket.on('table:occupied', (payload) => { /* ... */ })
socket.on('table:available', (payload) => { /* ... */ })

// Connection events
socket.on('connection:established', (payload) => { /* ... */ })
socket.on('error', (payload) => { /* ... */ })

// Heartbeat
socket.on('ping', () => socket.emit('pong'))
```

### REST API Enhancements

#### Push Notification Endpoints

```
POST /api/notifications/register
Body: {
  deviceToken: string,
  platform: "ios" | "android" | "web"
}
Response: {
  success: boolean,
  message: string
}

DELETE /api/notifications/unregister
Body: {
  deviceToken: string
}
Response: {
  success: boolean,
  message: string
}
```

## Implementation Plan

### Phase 1: Backend WebSocket Infrastructure (Week 1)

#### Tasks:
1. **Install Dependencies**
   - Add `socket.io` to package.json
   - Add `firebase-admin` for push notifications

2. **Create WebSocket Server**
   - File: `backend/src/socket/socket.server.js`
   - Initialize Socket.IO server
   - Attach to existing Express server
   - Configure CORS for WebSocket connections

3. **Implement Socket Middleware**
   - File: `backend/src/middlewares/socket.middleware.js`
   - JWT authentication for socket connections
   - Room authorization logic
   - Rate limiting

4. **Create Socket Manager**
   - File: `backend/src/socket/socket.manager.js`
   - Singleton pattern for global access
   - Methods: `emitToRoom()`, `emitToUser()`, `broadcastToKitchen()`
   - Event validation

5. **Integrate with Server**
   - Modify `backend/src/server.js` to initialize WebSocket server
   - Add graceful shutdown for socket connections

#### Deliverables:
- WebSocket server running alongside Express
- Authentication and authorization working
- Basic room management functional

### Phase 2: Backend Event Integration (Week 1-2)

#### Tasks:
1. **Enhance Order Controller**
   - Import Socket Manager
   - Emit `order:created` in `createOrder()`
   - Emit `order:updated` in `updateOrderStatus()`
   - Emit `order:cancelled` in `cancelOrder()`
   - Emit `waiter:called` in `callWaiter()`

2. **Enhance Table Controller**
   - Emit `table:occupied` when session starts
   - Emit `table:available` when session ends

3. **Create Push Notification Service**
   - File: `backend/src/services/push-notification.service.js`
   - Initialize Firebase Admin SDK
   - Implement `sendOrderNotification()`
   - Create notification templates

4. **Add Notification Endpoints**
   - File: `backend/src/routes/notification.routes.js`
   - POST `/api/notifications/register`
   - DELETE `/api/notifications/unregister`

5. **Integrate Push Notifications**
   - Call push notification service in `updateOrderStatus()`
   - Send notifications for: confirmed, ready, cancelled

#### Deliverables:
- All order events emitting via WebSocket
- Push notifications sending via FCM
- Device token registration working

### Phase 3: Frontend WebSocket Service (Week 2)

#### Tasks:
1. **Install Dependencies**
   - Add `socket_io_client` to pubspec.yaml
   - Add `firebase_messaging` for push notifications

2. **Create WebSocket Service**
   - File: `frontend/lib/core/services/websocket_service.dart`
   - Singleton pattern
   - Connection management with exponential backoff
   - Event subscription/unsubscription
   - Offline queue implementation

3. **Create WebSocket Provider**
   - File: `frontend/lib/state/websocket/websocket_provider.dart`
   - Expose connection state
   - Provide event listener registration
   - Notify UI of state changes

4. **Enhance Notification Service**
   - File: `frontend/lib/core/services/notification_service.dart`
   - Register FCM device token
   - Handle foreground/background notifications
   - Implement deep linking to order page

5. **Create Connection Status Widget**
   - File: `frontend/lib/presentation/widgets/connection_status_indicator.dart`
   - Display connection state (connected, reconnecting, offline)
   - Color-coded indicator (green, yellow, red)

#### Deliverables:
- WebSocket service connecting to backend
- Connection state management working
- Push notification registration functional

### Phase 4: Frontend UI Integration - Customer App (Week 2-3)

#### Tasks:
1. **Refactor Order Status Page**
   - Remove polling timer
   - Subscribe to `table:{tableId}` room on mount
   - Listen for `order:updated` events
   - Update UI in real-time
   - Add connection status indicator
   - Implement offline queue for "Call Waiter"

2. **Add Sound/Vibration Alerts**
   - Play sound when order is ready
   - Trigger vibration on mobile devices
   - Add settings to disable alerts

3. **Enhance In-App Notifications**
   - Show snackbar for order updates
   - Display notification dialog for important updates
   - Auto-dismiss after 5 seconds

4. **Test Offline Behavior**
   - Verify offline queue works
   - Test reconnection after network loss
   - Ensure UI shows offline state

#### Deliverables:
- Customer app receiving real-time order updates
- No more polling on order status page
- Offline queue functional

### Phase 5: Frontend UI Integration - Kitchen Dashboard (Week 3)

#### Tasks:
1. **Refactor Kitchen Orders Page**
   - Remove polling timer
   - Subscribe to `kitchen:{restaurantId}` room on mount
   - Listen for `order:created`, `order:updated` events
   - Update order list in real-time
   - Add connection status indicator

2. **Implement Sound Alerts**
   - Play notification sound for new orders
   - Play chime sound for ready orders
   - Add volume control in settings

3. **Add Order Timers**
   - Display elapsed time since order creation
   - Color-code timers (green < 10min, yellow 10-15min, red > 15min)
   - Flash red orders every 2 seconds

4. **Animate Order Transitions**
   - Animate new orders appearing at top
   - Animate status changes between groups
   - Smooth scroll to new orders

5. **Add Waiter Alert Display**
   - Listen for `waiter:called` events
   - Display notification with table number
   - Play bell sound for waiter calls

#### Deliverables:
- Kitchen dashboard receiving real-time order updates
- Sound alerts playing for new orders
- Order timers displaying with color coding
- Waiter alerts showing in real-time

### Phase 6: Testing & Optimization (Week 3-4)

#### Tasks:
1. **Load Testing**
   - Test with 100 concurrent connections
   - Test with 1000 concurrent connections
   - Measure event delivery latency
   - Identify bottlenecks

2. **Connection Resilience Testing**
   - Test reconnection after network loss
   - Test with poor network conditions
   - Verify offline queue works correctly
   - Test heartbeat mechanism

3. **Cross-Platform Testing**
   - Test on iOS devices
   - Test on Android devices
   - Test on web browsers
   - Verify push notifications on all platforms

4. **Performance Optimization**
   - Optimize event payload sizes
   - Implement event batching if needed
   - Add Redis Pub/Sub for multi-server scaling (if needed)
   - Optimize database queries triggered by events

5. **Error Handling & Logging**
   - Add comprehensive error logging
   - Implement error recovery mechanisms
   - Add monitoring for connection metrics
   - Create alerts for high error rates

#### Deliverables:
- System handling 1000+ concurrent connections
- Event delivery < 500ms
- Reconnection working reliably
- Comprehensive logging in place

### Phase 7: Migration & Rollout (Week 4)

#### Tasks:
1. **Gradual Rollout**
   - Deploy WebSocket server to staging
   - Test with internal users
   - Deploy to production with feature flag
   - Enable for 10% of users
   - Monitor metrics and errors
   - Gradually increase to 100%

2. **Remove Polling Code**
   - Once WebSocket is stable, remove polling timers
   - Clean up old code
   - Update documentation

3. **Documentation**
   - Document WebSocket API
   - Create troubleshooting guide
   - Update deployment guide
   - Create monitoring dashboard

#### Deliverables:
- WebSocket system live in production
- Polling code removed
- Documentation complete

## Technology Stack

### Backend
- **WebSocket Library**: Socket.IO v4.x
  - Automatic reconnection
  - Room management
  - Fallback to long-polling
  - Binary support
- **Push Notifications**: Firebase Admin SDK
  - Cross-platform support
  - Reliable delivery
  - Rich notifications
- **Authentication**: JWT (existing)
- **Database**: MongoDB (existing)

### Frontend
- **WebSocket Client**: socket_io_client v2.x
  - Compatible with Socket.IO server
  - Automatic reconnection
  - Event-based API
- **Push Notifications**: firebase_messaging v14.x
  - iOS and Android support
  - Foreground/background handling
  - Deep linking
- **State Management**: Provider (existing)
- **Local Storage**: shared_preferences (existing)

## Security Considerations

### Authentication
- JWT tokens passed in WebSocket handshake headers
- Tokens validated on connection and room subscription
- Expired tokens trigger disconnection

### Authorization
- Room subscriptions validated against user role
- Customers can only join rooms for their active orders
- Restaurant staff can only join rooms for their restaurant
- Unauthorized room access rejected with error message

### Rate Limiting
- Limit socket events to 100 per second per room
- Limit connection attempts to 5 per minute per IP
- Implement exponential backoff for reconnection

### Data Validation
- All event payloads validated against schemas
- Malformed events rejected with error response
- Input sanitization for chat messages

### CORS Configuration
- Restrict WebSocket connections to known origins
- Configure CORS headers for production domains

## Performance Considerations

### Connection Management
- Idle connections closed after 1 hour
- Heartbeat every 30 seconds to detect dead connections
- Graceful degradation to polling if WebSocket fails

### Event Broadcasting
- Use Socket.IO rooms for efficient broadcasting
- Avoid broadcasting to individual sockets when possible
- Batch events when appropriate

### Scalability
- Single server can handle 1000+ concurrent connections
- For scaling beyond 1000, implement Redis Pub/Sub adapter
- Horizontal scaling with multiple server instances

### Database Optimization
- Index on `tableId`, `restaurantId`, `status` for fast queries
- Use MongoDB change streams for real-time updates (future)
- Cache frequently accessed data (restaurant info, table info)

## Monitoring & Observability

### Metrics to Track
- Total active WebSocket connections
- Events per second (by type)
- Average event delivery latency
- Connection errors (by type)
- Reconnection attempts
- Push notification delivery rate

### Logging
- Log all connection lifecycle events
- Log all event broadcasts
- Log authorization failures
- Log errors with stack traces

### Health Checks
- WebSocket server health endpoint
- Connection count endpoint
- Event queue depth (if using queue)

### Alerts
- Alert if connection count drops suddenly
- Alert if event delivery latency > 2 seconds
- Alert if error rate > 5%
- Alert if push notification delivery rate < 90%

## Rollback Plan

### If WebSocket System Fails
1. Disable WebSocket feature flag
2. Re-enable polling timers in frontend
3. Investigate root cause
4. Fix issues in staging
5. Re-deploy with fixes

### Backward Compatibility
- Keep REST API endpoints functional
- Polling can work alongside WebSocket
- Gradual migration allows easy rollback

## Future Enhancements

### Phase 8: Real-time Chat (Future)
- Customer-to-waiter messaging
- Kitchen-to-waiter coordination
- Message history persistence
- Typing indicators

### Phase 9: Advanced Features (Future)
- Driver location tracking for delivery orders
- Real-time order analytics dashboard
- Multi-restaurant order aggregation
- Voice notifications for kitchen staff

## Conclusion

This design provides a comprehensive plan for implementing a robust, scalable, real-time order system for FoodieGo. The phased approach allows for incremental development and testing, minimizing risk while delivering value early. The architecture is designed to handle current needs while being extensible for future enhancements.
