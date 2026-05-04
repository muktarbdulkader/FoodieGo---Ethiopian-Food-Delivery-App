# Requirements Document: Real-time Order System

## Introduction

The Real-time Order System replaces the current polling-based order update mechanism (5-second intervals) with a WebSocket-based real-time communication system for the FoodieGo food delivery application. This system enables instant bidirectional communication between customers, kitchen staff, waiters, and administrators for dine-in orders, providing live order status updates, kitchen notifications, push notifications, and real-time messaging capabilities.

## Glossary

- **WebSocket_Server**: The backend server component that manages WebSocket connections and broadcasts real-time events
- **WebSocket_Client**: The frontend application component that establishes and maintains WebSocket connections
- **Order_Event**: A real-time notification triggered by order status changes, new orders, or updates
- **Kitchen_Dashboard**: The administrative interface displaying live order queues for kitchen staff
- **Customer_App**: The Flutter mobile/web application used by customers to place and track orders
- **Push_Notification_Service**: The service responsible for sending mobile push notifications via Firebase Cloud Messaging
- **Connection_Manager**: The component that handles WebSocket connection lifecycle, reconnection, and heartbeat
- **Event_Broadcaster**: The server component that distributes Order_Events to connected clients based on subscriptions
- **Order_Status**: The current state of an order (pending, confirmed, preparing, ready, completed, cancelled)
- **Table_Session**: An active dine-in session associated with a specific table
- **Waiter_Alert**: A real-time notification sent to restaurant staff when customers request assistance
- **Sound_Alert**: An audio notification played when specific events occur
- **Order_Timer**: A visual countdown showing elapsed time since order placement or status change
- **Socket_Room**: A logical grouping of WebSocket connections for targeted message broadcasting
- **Heartbeat**: A periodic ping/pong message to verify connection health
- **Reconnection_Strategy**: The algorithm for re-establishing dropped WebSocket connections with exponential backoff

## Requirements

### Requirement 1: WebSocket Connection Management

**User Story:** As a system administrator, I want reliable WebSocket connections with automatic reconnection, so that real-time updates remain functional even during network interruptions.

#### Acceptance Criteria

1. WHEN the Customer_App or Kitchen_Dashboard initializes, THE WebSocket_Client SHALL establish a connection to the WebSocket_Server within 5 seconds
2. WHEN a WebSocket connection is established, THE Connection_Manager SHALL send a Heartbeat message every 30 seconds
3. WHEN a Heartbeat response is not received within 10 seconds, THE Connection_Manager SHALL mark the connection as unhealthy
4. WHEN a WebSocket connection drops, THE Connection_Manager SHALL attempt reconnection using exponential backoff starting at 1 second with a maximum delay of 30 seconds
5. WHEN reconnection succeeds, THE WebSocket_Client SHALL re-subscribe to all previously active Socket_Rooms
6. WHEN a connection remains disconnected for more than 5 minutes, THE WebSocket_Client SHALL display a connection error message to the user
7. THE WebSocket_Server SHALL support at least 1000 concurrent connections per server instance
8. WHEN a client connects, THE WebSocket_Server SHALL authenticate the connection using JWT tokens from the authorization header

### Requirement 2: Real-time Order Status Updates

**User Story:** As a customer, I want to receive instant notifications when my order status changes, so that I know exactly when my food is ready without constantly checking.

#### Acceptance Criteria

1. WHEN an Order_Status changes, THE Event_Broadcaster SHALL emit an Order_Event to all clients subscribed to that order within 500 milliseconds
2. WHEN a customer places a dine-in order, THE WebSocket_Client SHALL subscribe to the Socket_Room for that Table_Session
3. WHEN an Order_Event is received, THE Customer_App SHALL update the order status display without requiring a page refresh
4. WHEN an order transitions to "confirmed" status, THE Customer_App SHALL display a success notification with the message "Your order has been accepted"
5. WHEN an order transitions to "ready" status, THE Customer_App SHALL display a notification with the message "Your order is ready" and trigger a Sound_Alert
6. WHEN an order transitions to "cancelled" status, THE Customer_App SHALL display an error notification with the cancellation reason
7. THE WebSocket_Server SHALL broadcast Order_Events only to authorized clients (order owner, restaurant staff, or assigned table)
8. WHEN multiple orders exist for a Table_Session, THE Event_Broadcaster SHALL send updates for all orders in that session

### Requirement 3: Live Kitchen Dashboard

**User Story:** As a kitchen staff member, I want to see new orders appear instantly on my dashboard with sound alerts, so that I can start preparing food immediately without delay.

#### Acceptance Criteria

1. WHEN a new dine-in order is created, THE Event_Broadcaster SHALL emit an Order_Event to the "kitchen" Socket_Room within 500 milliseconds
2. WHEN the Kitchen_Dashboard receives a new order event, THE Kitchen_Dashboard SHALL display the order at the top of the pending queue
3. WHEN a new order arrives, THE Kitchen_Dashboard SHALL play a Sound_Alert (notification sound) with volume configurable by the user
4. WHEN an order is displayed, THE Kitchen_Dashboard SHALL show an Order_Timer indicating elapsed time since order placement
5. WHEN an Order_Timer exceeds 15 minutes, THE Kitchen_Dashboard SHALL highlight the order in red to indicate urgency
6. WHEN a kitchen staff member updates an Order_Status, THE Kitchen_Dashboard SHALL broadcast the change to all connected kitchen clients within 500 milliseconds
7. THE Kitchen_Dashboard SHALL display orders grouped by status (pending, confirmed, preparing, ready) with real-time counts
8. WHEN an order is moved between status groups, THE Kitchen_Dashboard SHALL animate the transition for visual feedback

### Requirement 4: Push Notifications

**User Story:** As a customer, I want to receive mobile push notifications for important order updates, so that I am notified even when the app is in the background.

#### Acceptance Criteria

1. WHEN a customer installs the Customer_App, THE Customer_App SHALL request push notification permissions from the operating system
2. WHEN push notification permission is granted, THE Customer_App SHALL register the device token with the Push_Notification_Service
3. WHEN an order transitions to "confirmed" status, THE Push_Notification_Service SHALL send a push notification with title "Order Accepted" and body "Your order is being prepared"
4. WHEN an order transitions to "ready" status, THE Push_Notification_Service SHALL send a push notification with title "Order Ready" and body "Your food is ready for serving"
5. WHEN an order transitions to "cancelled" status, THE Push_Notification_Service SHALL send a push notification with title "Order Cancelled" and the cancellation reason
6. WHEN a push notification is sent, THE Push_Notification_Service SHALL include the order ID as metadata for deep linking
7. WHEN a customer taps a push notification, THE Customer_App SHALL navigate directly to the order status page for that order
8. THE Push_Notification_Service SHALL use Firebase Cloud Messaging for cross-platform delivery
9. WHEN the Customer_App is in the foreground, THE Customer_App SHALL display in-app notifications instead of system push notifications to avoid duplication

### Requirement 5: Real-time Table Status Updates

**User Story:** As a restaurant manager, I want to see table occupancy status update in real-time, so that I can efficiently manage seating and table turnover.

#### Acceptance Criteria

1. WHEN a customer scans a QR code and starts a Table_Session, THE Event_Broadcaster SHALL emit a table status event to the "restaurant-admin" Socket_Room within 500 milliseconds
2. WHEN a Table_Session becomes occupied, THE WebSocket_Server SHALL broadcast the table status change with isOccupied set to true
3. WHEN all orders for a Table_Session are marked as "completed", THE WebSocket_Server SHALL broadcast the table status change with isOccupied set to false
4. WHEN the restaurant admin views the table management page, THE WebSocket_Client SHALL subscribe to the "restaurant-admin" Socket_Room
5. THE Kitchen_Dashboard SHALL display real-time table occupancy indicators showing which tables have active orders
6. WHEN a table status changes, THE Kitchen_Dashboard SHALL update the table display within 500 milliseconds without page refresh

### Requirement 6: Customer-to-Waiter Messaging

**User Story:** As a customer, I want to send messages to the waiter from my table, so that I can request assistance or ask questions without leaving my seat.

#### Acceptance Criteria

1. WHEN a customer presses the "Call Waiter" button, THE WebSocket_Client SHALL emit a Waiter_Alert event to the "restaurant-staff" Socket_Room
2. WHEN a Waiter_Alert is received, THE Kitchen_Dashboard SHALL display a notification showing the table number and request message
3. WHEN a Waiter_Alert is received, THE Kitchen_Dashboard SHALL play a Sound_Alert (bell sound) to notify staff
4. WHEN a customer sends a message, THE WebSocket_Server SHALL store the message in the order's chat history
5. WHEN a waiter responds to a message, THE Event_Broadcaster SHALL send the response to the customer's WebSocket_Client within 500 milliseconds
6. THE Customer_App SHALL display a chat interface showing message history with timestamps
7. WHEN a new message arrives, THE Customer_App SHALL display an unread message indicator
8. THE WebSocket_Server SHALL limit message length to 500 characters to prevent abuse

### Requirement 7: Kitchen-to-Waiter Coordination

**User Story:** As a kitchen staff member, I want to notify waiters when orders are ready, so that food can be served promptly while still hot.

#### Acceptance Criteria

1. WHEN an order transitions to "ready" status, THE Event_Broadcaster SHALL emit a notification to the "restaurant-staff" Socket_Room within 500 milliseconds
2. WHEN a ready notification is received, THE Kitchen_Dashboard SHALL display the table number and order details prominently
3. WHEN a ready notification is received, THE Kitchen_Dashboard SHALL play a Sound_Alert (chime sound) to alert waiters
4. THE Kitchen_Dashboard SHALL display a list of all orders in "ready" status with Order_Timers showing wait time
5. WHEN a ready order's Order_Timer exceeds 5 minutes, THE Kitchen_Dashboard SHALL highlight the order in orange to indicate delayed service
6. WHEN a waiter marks an order as "completed", THE Event_Broadcaster SHALL remove the order from the ready queue for all connected clients within 500 milliseconds

### Requirement 8: WebSocket Event Types and Payload Structure

**User Story:** As a developer, I want standardized event types and payload structures, so that I can reliably implement real-time features across the application.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL support the following event types: "order:created", "order:updated", "order:cancelled", "table:occupied", "table:available", "waiter:called", "message:sent", "connection:established"
2. WHEN an Order_Event is emitted, THE Event_Broadcaster SHALL include the following fields: eventType, orderId, orderNumber, tableId, tableNumber, status, timestamp, restaurantId
3. WHEN a Waiter_Alert is emitted, THE Event_Broadcaster SHALL include the following fields: eventType, tableId, tableNumber, message, timestamp, customerId
4. WHEN a table status event is emitted, THE Event_Broadcaster SHALL include the following fields: eventType, tableId, tableNumber, isOccupied, timestamp, restaurantId
5. THE WebSocket_Server SHALL validate all incoming event payloads against defined schemas and reject malformed messages
6. WHEN an invalid event is received, THE WebSocket_Server SHALL send an error response with a descriptive message
7. THE WebSocket_Server SHALL use JSON format for all event payloads

### Requirement 9: Socket Room Management and Authorization

**User Story:** As a security engineer, I want proper authorization for socket room subscriptions, so that users only receive events they are permitted to see.

#### Acceptance Criteria

1. WHEN a client attempts to join a Socket_Room, THE WebSocket_Server SHALL verify the client's JWT token and role
2. WHEN a customer joins a table-specific Socket_Room, THE WebSocket_Server SHALL verify the customer has an active order for that table
3. WHEN a restaurant staff member joins the "kitchen" Socket_Room, THE WebSocket_Server SHALL verify the user has role "restaurant" and matches the restaurantId
4. WHEN a client joins the "restaurant-admin" Socket_Room, THE WebSocket_Server SHALL verify the user has role "restaurant"
5. THE WebSocket_Server SHALL automatically remove clients from Socket_Rooms when their authorization expires
6. WHEN a client attempts to join an unauthorized Socket_Room, THE WebSocket_Server SHALL reject the request and send an error message
7. THE WebSocket_Server SHALL maintain a mapping of Socket_Rooms to connected client IDs for efficient broadcasting

### Requirement 10: Order Preparation Timer and Priority Indicators

**User Story:** As a kitchen manager, I want visual indicators showing order age and priority, so that I can ensure timely food preparation and avoid delays.

#### Acceptance Criteria

1. WHEN an order is displayed on the Kitchen_Dashboard, THE Kitchen_Dashboard SHALL show an Order_Timer counting up from order creation time
2. WHEN an Order_Timer is between 0-10 minutes, THE Kitchen_Dashboard SHALL display the timer in green
3. WHEN an Order_Timer is between 10-15 minutes, THE Kitchen_Dashboard SHALL display the timer in yellow
4. WHEN an Order_Timer exceeds 15 minutes, THE Kitchen_Dashboard SHALL display the timer in red and flash the order card every 2 seconds
5. THE Kitchen_Dashboard SHALL allow drag-and-drop reordering of orders within the same status group
6. WHEN an order is reordered, THE Kitchen_Dashboard SHALL persist the priority order in local storage
7. THE Kitchen_Dashboard SHALL display a badge showing the total number of pending orders requiring attention

### Requirement 11: Connection State Indicators

**User Story:** As a user, I want to see the connection status of the real-time system, so that I know whether I'm receiving live updates or experiencing connectivity issues.

#### Acceptance Criteria

1. WHEN the WebSocket connection is active and healthy, THE Customer_App SHALL display a green "Live" indicator
2. WHEN the WebSocket connection is reconnecting, THE Customer_App SHALL display a yellow "Reconnecting" indicator with a spinner
3. WHEN the WebSocket connection is disconnected, THE Customer_App SHALL display a red "Offline" indicator
4. WHEN the connection state changes, THE Customer_App SHALL update the indicator within 1 second
5. THE Kitchen_Dashboard SHALL display the connection status indicator in the top navigation bar
6. WHEN the connection is offline for more than 30 seconds, THE Customer_App SHALL display a banner message: "Connection lost. Attempting to reconnect..."
7. WHEN the connection is restored after being offline, THE Customer_App SHALL display a success message: "Connection restored" for 3 seconds

### Requirement 12: Vibration Alerts for Mobile Devices

**User Story:** As a customer using a mobile device, I want vibration alerts for important order updates, so that I notice notifications even in noisy environments.

#### Acceptance Criteria

1. WHEN an order transitions to "ready" status, THE Customer_App SHALL trigger a vibration pattern (200ms on, 100ms off, 200ms on) on mobile devices
2. WHEN a new message is received from a waiter, THE Customer_App SHALL trigger a short vibration (100ms) on mobile devices
3. WHEN an order is cancelled, THE Customer_App SHALL trigger a long vibration (500ms) on mobile devices
4. THE Customer_App SHALL request vibration permissions on mobile platforms that require explicit permission
5. THE Customer_App SHALL provide a settings option to disable vibration alerts
6. WHEN vibration is disabled in settings, THE Customer_App SHALL not trigger any vibration alerts

### Requirement 13: Offline Queue and Message Persistence

**User Story:** As a customer, I want my actions to be queued when offline, so that they are sent automatically when the connection is restored.

#### Acceptance Criteria

1. WHEN the WebSocket connection is offline and a customer sends a message, THE WebSocket_Client SHALL store the message in a local queue
2. WHEN the WebSocket connection is restored, THE WebSocket_Client SHALL send all queued messages in chronological order within 5 seconds
3. WHEN a queued message is successfully sent, THE WebSocket_Client SHALL remove it from the queue
4. WHEN a queued message fails to send after reconnection, THE WebSocket_Client SHALL retry up to 3 times with 2-second intervals
5. WHEN all retry attempts fail, THE Customer_App SHALL display an error message: "Failed to send message. Please try again."
6. THE WebSocket_Client SHALL persist the queue to local storage to survive app restarts
7. THE WebSocket_Client SHALL limit the queue size to 50 messages to prevent memory issues

### Requirement 14: Performance and Scalability

**User Story:** As a system architect, I want the real-time system to handle high load efficiently, so that the application remains responsive during peak hours.

#### Acceptance Criteria

1. THE WebSocket_Server SHALL handle at least 1000 concurrent connections per server instance without degradation
2. WHEN broadcasting an Order_Event to a Socket_Room with 100 clients, THE Event_Broadcaster SHALL deliver the event to all clients within 1 second
3. THE WebSocket_Server SHALL use Redis Pub/Sub for cross-server event distribution in multi-instance deployments
4. THE WebSocket_Server SHALL limit event broadcast rate to 100 events per second per Socket_Room to prevent flooding
5. WHEN event rate exceeds the limit, THE WebSocket_Server SHALL queue events and process them with a 10-millisecond delay
6. THE Connection_Manager SHALL close idle connections after 1 hour of inactivity to free resources
7. THE WebSocket_Server SHALL log connection metrics (total connections, events per second, average latency) every 60 seconds

### Requirement 15: Error Handling and Logging

**User Story:** As a DevOps engineer, I want comprehensive error logging for the real-time system, so that I can diagnose and resolve issues quickly.

#### Acceptance Criteria

1. WHEN a WebSocket connection error occurs, THE WebSocket_Server SHALL log the error with timestamp, client ID, error type, and error message
2. WHEN an event broadcast fails, THE Event_Broadcaster SHALL log the failure with event type, target Socket_Room, and error details
3. WHEN a client sends a malformed event, THE WebSocket_Server SHALL log the validation error and the invalid payload
4. THE WebSocket_Server SHALL log all connection lifecycle events (connect, disconnect, reconnect) with client metadata
5. WHEN an authorization failure occurs, THE WebSocket_Server SHALL log the failure with attempted Socket_Room and user role
6. THE WebSocket_Server SHALL expose a health check endpoint returning connection count and server status
7. THE WebSocket_Server SHALL integrate with the existing logging infrastructure using the same log format and transport

## Implementation Notes

### Technology Stack
- **Backend WebSocket Library**: Socket.IO (Node.js) - provides automatic reconnection, room management, and fallback to long-polling
- **Frontend WebSocket Client**: socket.io-client (Flutter via flutter_socket_io package)
- **Push Notifications**: Firebase Cloud Messaging (FCM) for cross-platform mobile notifications
- **Message Queue**: Redis Pub/Sub for multi-server event distribution (optional for scaling)
- **Authentication**: JWT tokens passed in WebSocket handshake headers

### Parser and Serializer Requirements
This feature does not introduce new data formats requiring custom parsers. All WebSocket events use JSON serialization provided by Socket.IO, which handles parsing and serialization automatically.

### Integration Points
- Existing Order model and controller (backend/src/models/Order.js, backend/src/controllers/order.controller.js)
- Existing authentication middleware (backend/src/middlewares/auth.middleware.js)
- Existing notification service (frontend/lib/core/services/notification_service.dart)
- Existing order status page (frontend/lib/presentation/pages/dine_in/order_status_page.dart)
- Existing kitchen orders page (frontend/lib/presentation/pages/admin/kitchen_orders_page.dart)

### Migration Strategy
The real-time system will be implemented alongside the existing polling mechanism initially. Once WebSocket functionality is verified in production, the polling code can be removed in a subsequent release. This allows for gradual rollout and easy rollback if issues arise.
