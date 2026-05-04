# Implementation Tasks: Real-time Order System

## Phase 1: Backend WebSocket Infrastructure ✅ COMPLETED

- [x] 1.1 Install Dependencies
  - [x] 1.1.1 Add socket.io to package.json
  - [x] 1.1.2 Verify socket.io version compatibility

- [x] 1.2 Create WebSocket Server
  - [x] 1.2.1 Create backend/src/socket/socket.server.js
  - [x] 1.2.2 Initialize Socket.IO server with CORS configuration
  - [x] 1.2.3 Implement connection handler
  - [x] 1.2.4 Implement room join/leave handlers
  - [x] 1.2.5 Implement heartbeat/ping-pong mechanism

- [x] 1.3 Implement Socket Middleware
  - [x] 1.3.1 Create backend/src/middlewares/socket.middleware.js
  - [x] 1.3.2 Implement JWT authentication middleware
  - [x] 1.3.3 Implement room authorization middleware
  - [x] 1.3.4 Implement rate limiting middleware

- [x] 1.4 Create Socket Manager
  - [x] 1.4.1 Create backend/src/socket/socket.manager.js
  - [x] 1.4.2 Implement singleton pattern
  - [x] 1.4.3 Implement emitToRoom() method
  - [x] 1.4.4 Implement emitToUser() method
  - [x] 1.4.5 Implement broadcastToKitchen() method

- [x] 1.5 Integrate with Server
  - [x] 1.5.1 Modify backend/src/server.js to initialize WebSocket
  - [x] 1.5.2 Add graceful shutdown for socket connections
  - [x] 1.5.3 Test WebSocket server starts correctly

## Phase 2: Backend Event Integration ✅ COMPLETED

- [x] 2.1 Enhance Order Controller
  - [x] 2.1.1 Import Socket Manager in order controller
  - [x] 2.1.2 Emit order:created in createOrder()
  - [x] 2.1.3 Emit order:updated in updateOrderStatus()
  - [x] 2.1.4 Emit order:cancelled in cancelOrder()
  - [x] 2.1.5 Emit waiter:called in callWaiter()

- [x] 2.2 Fix Table Number Population
  - [x] 2.2.1 Update getAllOrders to populate tableId with tableNumber
  - [x] 2.2.2 Update frontend Order model to extract tableNumber

- [x] 2.3 Test Backend Events
  - [x] 2.3.1 Verify events emit correctly
  - [x] 2.3.2 Test room broadcasting
  - [x] 2.3.3 Verify event payloads match design

## Phase 3: Frontend WebSocket Service ✅ COMPLETED

- [x] 3.1 Install Dependencies
  - [x] 3.1.1 Add socket_io_client to pubspec.yaml
  - [x] 3.1.2 Add audioplayers to pubspec.yaml
  - [x] 3.1.3 Add vibration to pubspec.yaml

- [x] 3.2 Create WebSocket Service
  - [x] 3.2.1 Create frontend/lib/core/services/websocket_service.dart
  - [x] 3.2.2 Implement singleton pattern
  - [x] 3.2.3 Implement connection management with exponential backoff
  - [x] 3.2.4 Implement event subscription/unsubscription
  - [x] 3.2.5 Implement offline queue
  - [x] 3.2.6 Implement heartbeat mechanism

- [x] 3.3 Create WebSocket Provider
  - [x] 3.3.1 Create frontend/lib/state/websocket/websocket_provider.dart
  - [x] 3.3.2 Expose connection state
  - [x] 3.3.3 Provide event listener registration
  - [x] 3.3.4 Notify UI of state changes

- [x] 3.4 Create Connection Status Widget
  - [x] 3.4.1 Create frontend/lib/presentation/widgets/connection_status_indicator.dart
  - [x] 3.4.2 Display connection state (connected, reconnecting, offline)
  - [x] 3.4.3 Color-coded indicator (green, yellow, red)

- [x] 3.5 Create Order Timer Widget
  - [x] 3.5.1 Create frontend/lib/presentation/widgets/order_timer.dart
  - [x] 3.5.2 Display elapsed time since order creation
  - [x] 3.5.3 Color-code timers (green < 10min, orange 10-15min, red > 15min)
  - [x] 3.5.4 Implement flashing animation for red timers

- [x] 3.6 Create Connection Banner Widget
  - [x] 3.6.1 Create frontend/lib/presentation/widgets/connection_banner.dart
  - [x] 3.6.2 Show banner when connection is lost
  - [x] 3.6.3 Show banner when connection is restored
  - [x] 3.6.4 Auto-dismiss after 3 seconds

- [x] 3.7 Add WebSocket Provider to App
  - [x] 3.7.1 Add WebSocketProvider to MultiProvider in main.dart
  - [x] 3.7.2 Fix ConnectionState naming conflict

- [x] 3.8 Update pubspec.yaml
  - [x] 3.8.1 Add assets section for sound files
  - [x] 3.8.2 Reference notification.mp3 and bell.mp3

## Phase 4: Frontend UI Integration - Customer App

- [x] 4.1 Refactor Order Status Page
  - [x] 4.1.1 Remove polling timer from OrderStatusPage
  - [x] 4.1.2 Subscribe to table:{tableId} room in initState
  - [x] 4.1.3 Listen for order:updated events
  - [x] 4.1.4 Update UI in real-time when events received
  - [x] 4.1.5 Unsubscribe from room in dispose
  - [x] 4.1.6 Add ConnectionBanner wrapper
  - [x] 4.1.7 Add ConnectionStatusIndicator to AppBar

- [ ] 4.2 Implement Vibration Alerts
  - [x] 4.2.1 Add vibration when order status changes to "ready"
  - [x] 4.2.2 Add vibration when order is cancelled
  - [~] 4.2.3 Test vibration on Android device
  - [~] 4.2.4 Test vibration on iOS device

- [ ] 4.3 Enhance In-App Notifications
  - [x] 4.3.1 Show snackbar for order:updated events
  - [x] 4.3.2 Show dialog for order:cancelled events
  - [x] 4.3.3 Auto-dismiss snackbar after 5 seconds
  - [ ] 4.3.4 Add sound to notifications (optional)

- [ ] 4.4 Implement Offline Queue for Call Waiter
  - [x] 4.4.1 Queue "Call Waiter" action when offline
  - [x] 4.4.2 Send queued actions when connection restored
  - [x] 4.4.3 Show pending indicator while action is queued
  - [~] 4.4.4 Test offline queue functionality

- [ ] 4.5 Test Customer App
  - [~] 4.5.1 Test real-time order updates
  - [~] 4.5.2 Test connection status indicator
  - [~] 4.5.3 Test offline behavior
  - [~] 4.5.4 Test reconnection after network loss
  - [~] 4.5.5 Verify no polling timers remain

## Phase 5: Frontend UI Integration - Kitchen Dashboard

- [x] 5.1 Refactor Kitchen Orders Page
  - [x] 5.1.1 Remove polling timer from KitchenOrdersPage
  - [x] 5.1.2 Subscribe to kitchen:{restaurantId} room in initState
  - [x] 5.1.3 Listen for order:created events
  - [x] 5.1.4 Listen for order:updated events
  - [x] 5.1.5 Listen for waiter:called events
  - [x] 5.1.6 Update order list in real-time
  - [x] 5.1.7 Unsubscribe from room in dispose
  - [x] 5.1.8 Add ConnectionBanner wrapper (already done)
  - [x] 5.1.9 Add ConnectionStatusIndicator to AppBar (already done)

- [ ] 5.2 Implement Sound Alerts
  - [~] 5.2.1 Create assets/sounds/notification.mp3 file
  - [~] 5.2.2 Create assets/sounds/bell.mp3 file
  - [x] 5.2.3 Play notification sound for new orders (already implemented)
  - [x] 5.2.4 Play bell sound for waiter calls (already implemented)
  - [~] 5.2.5 Test sound playback on web
  - [~] 5.2.6 Test sound playback on mobile
  - [ ] 5.2.7* Add volume control in settings (optional)

- [ ] 5.3 Integrate Order Timers
  - [x] 5.3.1 Add OrderTimer widget to order cards (already added)
  - [~] 5.3.2 Verify color coding works correctly
  - [~] 5.3.3 Verify flashing animation for red timers
  - [~] 5.3.4 Test timer updates in real-time

- [ ] 5.4* Animate Order Transitions (optional)
  - [ ]* 5.4.1 Animate new orders appearing at top
  - [ ]* 5.4.2 Animate status changes between filter groups
  - [ ]* 5.4.3 Smooth scroll to new orders
  - [ ]* 5.4.4 Add fade-in animation for new orders

- [ ] 5.5 Test Kitchen Dashboard
  - [~] 5.5.1 Test real-time order updates
  - [~] 5.5.2 Test sound alerts
  - [~] 5.5.3 Test waiter call alerts
  - [~] 5.5.4 Test connection status indicator
  - [~] 5.5.5 Test offline behavior
  - [~] 5.5.6 Verify no polling timers remain

## Phase 6: Testing & Optimization

- [ ] 6.1 Connection Resilience Testing
  - [~] 6.1.1 Test reconnection after network loss
  - [~] 6.1.2 Test with poor network conditions (throttled connection)
  - [~] 6.1.3 Verify offline queue works correctly
  - [~] 6.1.4 Test heartbeat mechanism
  - [~] 6.1.5 Test exponential backoff reconnection

- [ ] 6.2 Cross-Platform Testing
  - [~] 6.2.1 Test on Android device
  - [~] 6.2.2 Test on iOS device (if available)
  - [~] 6.2.3 Test on web browser (Chrome)
  - [~] 6.2.4 Test on web browser (Firefox)
  - [~] 6.2.5 Test on web browser (Safari)

- [ ] 6.3 Functional Testing
  - [~] 6.3.1 Test customer placing order and receiving updates
  - [~] 6.3.2 Test kitchen receiving new orders
  - [~] 6.3.3 Test kitchen updating order status
  - [~] 6.3.4 Test customer receiving status updates
  - [~] 6.3.5 Test waiter call functionality
  - [~] 6.3.6 Test multiple customers at different tables
  - [~] 6.3.7 Test multiple kitchen staff viewing same orders

- [ ] 6.4 Performance Testing
  - [~] 6.4.1 Test with 10 concurrent connections
  - [~] 6.4.2 Test with 50 concurrent connections
  - [~] 6.4.3 Measure event delivery latency
  - [~] 6.4.4 Monitor memory usage on client
  - [~] 6.4.5 Monitor CPU usage on server
  - [~] 6.4.6 Identify and fix performance bottlenecks

- [ ] 6.5 Error Handling Testing
  - [~] 6.5.1 Test with invalid JWT token
  - [~] 6.5.2 Test with expired JWT token
  - [~] 6.5.3 Test unauthorized room access
  - [~] 6.5.4 Test malformed event payloads
  - [~] 6.5.5 Verify error messages are user-friendly

- [ ] 6.6 Code Quality & Optimization
  - [~] 6.6.1 Fix all linter warnings in Dart code
  - [~] 6.6.2 Fix all ESLint warnings in Node.js code
  - [~] 6.6.3 Add error logging to WebSocket service
  - [~] 6.6.4 Add error logging to Socket Manager
  - [~] 6.6.5 Optimize event payload sizes
  - [ ] 6.6.6 Review and optimize database queries

## Phase 7: Migration & Rollout

- [ ] 7.1 Initialize WebSocket on Login
  - [ ] 7.1.1 Connect WebSocket when user logs in
  - [ ] 7.1.2 Pass JWT token to WebSocket service
  - [ ] 7.1.3 Disconnect WebSocket when user logs out
  - [ ] 7.1.4 Test login/logout flow

- [ ] 7.2 Staging Deployment
  - [ ] 7.2.1 Deploy backend to staging environment
  - [ ] 7.2.2 Deploy frontend to staging environment
  - [ ] 7.2.3 Test with internal users
  - [ ] 7.2.4 Collect feedback and fix issues

- [ ] 7.3 Production Deployment
  - [ ] 7.3.1 Deploy backend to production
  - [ ] 7.3.2 Deploy frontend to production
  - [ ] 7.3.3 Monitor error logs for first 24 hours
  - [ ] 7.3.4 Monitor connection metrics
  - [ ] 7.3.5 Monitor event delivery latency

- [ ] 7.4 Remove Polling Code
  - [ ] 7.4.1 Remove polling timer from OrderStatusPage
  - [ ] 7.4.2 Remove polling timer from KitchenOrdersPage
  - [ ] 7.4.3 Clean up unused polling code
  - [ ] 7.4.4 Test that real-time updates still work

- [ ] 7.5 Documentation
  - [ ] 7.5.1 Document WebSocket API events
  - [ ] 7.5.2 Create troubleshooting guide
  - [ ] 7.5.3 Update deployment guide
  - [ ] 7.5.4 Document monitoring setup
  - [ ] 7.5.5 Create user guide for real-time features

- [ ] 7.6 Monitoring Setup
  - [ ] 7.6.1 Set up monitoring for active connections
  - [ ] 7.6.2 Set up monitoring for event delivery latency
  - [ ] 7.6.3 Set up alerts for connection drops
  - [ ] 7.6.4 Set up alerts for high error rates
  - [ ] 7.6.5 Create monitoring dashboard

## Notes

- Tasks marked with `*` are optional enhancements
- Phases 1-3 are completed
- Currently working on Phase 4
- Sound files (notification.mp3, bell.mp3) need to be created or sourced
- WebSocket connection initialization on login is part of Phase 7 but can be done earlier
