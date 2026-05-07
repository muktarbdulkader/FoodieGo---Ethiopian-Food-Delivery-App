# FoodieGo - Complete Application Documentation

## 🍽️ Overview

**FoodieGo** is a production-ready Ethiopian food delivery platform built with Flutter (frontend) and Node.js/Express (backend). It supports multiple user roles including customers, restaurant admins, delivery drivers, and dine-in patrons.

---

## 📱 Application Name

**FoodieGo** - "Delivering Ethiopian Flavors to Your Doorstep"

---

## 🏗️ Architecture Overview

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.5+ (Dart) |
| **Backend** | Node.js + Express.js |
| **Database** | MongoDB |
| **State Management** | Provider Pattern |
| **Authentication** | JWT Tokens + bcrypt |
| **Location Services** | Geolocator + Geocoding |
| **Notifications** | Firebase Cloud Messaging |
| **Storage** | SharedPreferences (local) |

---

## 👥 User Roles

### 1. **Customer** 👤
- Browse restaurants and food items
- Place delivery orders
- Track orders in real-time
- Make payments (Telebirr, M-Pesa, CBE Birr, Cash, Card)
- Write reviews and ratings
- View order history
- Use referral codes

### 2. **Restaurant Admin** 🏪
- Manage restaurant profile
- Add/edit/delete food items
- Process incoming orders
- View sales analytics and revenue
- Manage table reservations
- Handle event bookings
- View customer reviews

### 3. **Delivery Driver** 🚚
- Accept delivery assignments
- Update delivery status
- View delivery history
- Navigate to customer locations
- Receive push notifications for new orders

### 4. **Dine-in Customer** 🍽️
- Scan QR code at table
- Browse menu digitally
- Place orders without waiting for waiter
- Split bills
- Rate dining experience

---

## 📁 Project Structure

### Frontend Structure (`frontend/lib/`)

```
lib/
├── core/
│   ├── constants/          # API endpoints, app constants
│   ├── theme/              # AppTheme, colors, typography
│   └── utils/              # StorageUtils, helpers
├── data/
│   ├── models/             # Data classes (User, Food, Order, etc.)
│   ├── repositories/       # Data access layer
│   └── services/           # API service, WebSocket
├── presentation/
│   ├── pages/              # All UI screens
│   │   ├── admin/          # Admin dashboard, food management
│   │   ├── auth/           # Login, register, role selection
│   │   ├── cart/           # Shopping cart
│   │   ├── checkout/       # Payment and order confirmation
│   │   ├── delivery/       # Driver dashboard
│   │   ├── dine_in/        # QR scanner, table ordering
│   │   ├── events/         # Event booking
│   │   ├── food/           # Food details, restaurant menu
│   │   ├── home/           # Main browsing interface
│   │   ├── location/       # Address picker, map
│   │   ├── orders/         # Order history, tracking
│   │   ├── profile/        # User profile, settings
│   │   └── splash/         # App initialization
│   └── widgets/            # Reusable UI components
├── state/
│   ├── admin/              # AdminProvider
│   ├── auth/               # AuthProvider
│   ├── cart/               # CartProvider
│   ├── dine_in/            # DineInProvider
│   ├── food/               # FoodProvider
│   ├── language/           # LanguageProvider
│   ├── order/              # OrderProvider
│   └── websocket/          # WebSocketProvider
└── main.dart               # App entry point
```

### Backend Structure (`backend/src/`)

```
src/
├── config/                 # Database connection
├── controllers/            # Request handlers
│   ├── auth.controller.js
│   ├── food.controller.js
│   ├── order.controller.js
│   └── ...
├── middlewares/            # Auth, validation, error handling
├── models/                 # Mongoose schemas
│   ├── User.js
│   ├── Food.js
│   ├── Order.js
│   ├── Restaurant.js
│   ├── EventBooking.js
│   ├── Table.js
│   ├── Review.js
│   ├── Promotion.js
│   └── OTP.js
├── routes/                 # API route definitions
│   ├── auth.routes.js
│   ├── food.routes.js
│   ├── order.routes.js
│   ├── restaurant.routes.js
│   ├── table.routes.js
│   ├── eventBooking.routes.js
│   ├── promotion.routes.js
│   ├── payment.routes.js
│   └── review.routes.js
├── services/               # Business logic
├── socket/                 # WebSocket handlers
├── utils/                  # Helper functions, seed data
├── app.js                  # Express app configuration
└── server.js               # Server entry point
```

---

## 🔐 Authentication System

### JWT-Based Authentication

```dart
// Token structure
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "email": "...",
    "role": "user|admin|delivery",
    "restaurant": "..."  // for admins
  }
}
```

### Session Management
- Separate auth providers for each role
- Session type stored in local storage
- Automatic token refresh
- 401 unauthorized handling per session

### Admin Registration Code
```
FOODIEGO_ADMIN_2024
```

---

## 💾 Data Models

### User Model
```javascript
{
  name: String,
  email: String,
  password: String (hashed),
  phone: String,
  role: Enum['user', 'admin', 'delivery', 'superadmin'],
  restaurant: ObjectId,  // for admins
  avatar: String,
  addresses: [{
    label: String,
    address: String,
    location: { lat: Number, lng: Number }
  }],
  referralCode: String,
  referredBy: ObjectId,
  fcmToken: String  // for push notifications
}
```

### Food Model
```javascript
{
  name: String,
  description: String,
  price: Number,
  category: String,
  restaurant: ObjectId,
  image: String,
  rating: Number,
  reviewCount: Number,
  preparationTime: Number,  // minutes
  calories: Number,
  isAvailable: Boolean,
  isPopular: Boolean,
  tags: [String]
}
```

### Order Model
```javascript
{
  user: ObjectId,
  items: [{
    food: ObjectId,
    quantity: Number,
    price: Number
  }],
  restaurant: ObjectId,
  status: Enum['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'],
  deliveryAddress: {
    address: String,
    location: { lat: Number, lng: Number }
  },
  paymentMethod: Enum['telebirr', 'mpesa', 'cbe_birr', 'cash', 'card'],
  paymentStatus: Enum['pending', 'completed', 'failed'],
  totalAmount: Number,
  deliveryFee: Number,
  discount: Number,
  driver: ObjectId,
  estimatedDeliveryTime: Date,
  actualDeliveryTime: Date,
  specialInstructions: String
}
```

### Restaurant Model
```javascript
{
  name: String,
  description: String,
  cuisine: String,
  address: String,
  location: { lat: Number, lng: Number },
  phone: String,
  email: String,
  images: [String],
  logo: String,
  rating: Number,
  reviewCount: Number,
  openingHours: {
    monday: { open: String, close: String },
    // ... other days
  },
  isActive: Boolean,
  deliveryRadius: Number,  // km
  minimumOrder: Number
}
```

### Table Model
```javascript
{
  restaurant: ObjectId,
  tableNumber: String,
  capacity: Number,
  qrCode: String,
  status: Enum['available', 'occupied', 'reserved'],
  currentOrder: ObjectId
}
```

### Event Booking Model
```javascript
{
  user: ObjectId,
  restaurant: ObjectId,
  eventType: String,
  date: Date,
  time: String,
  numberOfGuests: Number,
  specialRequests: String,
  status: Enum['pending', 'confirmed', 'cancelled'],
  totalAmount: Number
}
```

### Referral Model
```javascript
{
  referrer: ObjectId,
  referee: ObjectId,
  code: String,
  rewardAmount: Number,
  status: Enum['pending', 'completed'],
  createdAt: Date
}
```

---

## 🔌 API Endpoints

### Authentication (`/api/auth`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | User registration |
| POST | `/login` | User login |
| POST | `/admin/register` | Admin registration (requires code) |
| POST | `/admin/login` | Admin login |
| POST | `/delivery/login` | Driver login |
| POST | `/refresh` | Refresh access token |
| POST | `/logout` | Logout user |
| POST | `/forgot-password` | Request password reset |
| POST | `/verify-otp` | Verify OTP code |
| POST | `/reset-password` | Reset password |

### Foods (`/api/foods`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all foods |
| GET | `/:id` | Get food details |
| GET | `/restaurant/:id` | Get foods by restaurant |
| GET | `/category/:category` | Get foods by category |
| POST | `/` | Create food (admin) |
| PUT | `/:id` | Update food (admin) |
| DELETE | `/:id` | Delete food (admin) |

### Orders (`/api/orders`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get user orders |
| GET | `/:id` | Get order details |
| POST | `/` | Create order |
| PUT | `/:id/status` | Update order status |
| PUT | `/:id/assign-driver` | Assign delivery driver |
| GET | `/restaurant/:id` | Get restaurant orders (admin) |

### Restaurants (`/api/restaurants`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all restaurants |
| GET | `/:id` | Get restaurant details |
| POST | `/` | Create restaurant (superadmin) |
| PUT | `/:id` | Update restaurant |
| GET | `/:id/stats` | Get restaurant analytics |

### Tables (`/api/tables`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/restaurant/:id` | Get restaurant tables |
| POST | `/` | Create table (admin) |
| PUT | `/:id` | Update table status |
| POST | `/:id/scan` | Scan QR and place order |

### Event Bookings (`/api/event-bookings`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get user bookings |
| POST | `/` | Create booking |
| PUT | `/:id` | Update booking status |

### Payments (`/api/payments`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/initialize` | Initialize payment |
| POST | `/verify` | Verify payment |
| POST | `/callback` | Payment gateway callback |

---

## 🎨 UI/UX Design System

### Color Palette
```dart
// Primary Colors
primaryColor: Color(0xFFFF6B35)  // Warm Orange
secondaryColor: Color(0xFF2E7D32)  // Ethiopian Green
accentColor: Color(0xFFFFB74D)  // Light Orange

// Background Colors
backgroundColor: Color(0xFFF5F5F5)  // Light Gray
surfaceColor: Colors.white
cardColor: Colors.white

// Text Colors
textPrimaryColor: Color(0xFF212121)  // Dark Gray
textSecondaryColor: Color(0xFF757575)  // Medium Gray
textHintColor: Color(0xFF9E9E9E)  // Light Gray

// Status Colors
successColor: Color(0xFF4CAF50)
errorColor: Color(0xFFE53935)
warningColor: Color(0xFFFF9800)
infoColor: Color(0xFF2196F3)
```

### Typography
```dart
// Font Family
fontFamily: 'Poppins'

// Text Styles
displayLarge: 32px, Bold
displayMedium: 28px, Bold
displaySmall: 24px, Bold
headlineLarge: 22px, SemiBold
headlineMedium: 20px, SemiBold
headlineSmall: 18px, SemiBold
titleLarge: 16px, Medium
titleMedium: 14px, Medium
titleSmall: 12px, Medium
bodyLarge: 16px, Regular
bodyMedium: 14px, Regular
bodySmall: 12px, Regular
```

### Component Guidelines
- **Cards**: Rounded corners (16px), subtle shadow (elevation 2)
- **Buttons**: Full-width on mobile, 48px height, 8px border radius
- **Inputs**: Underlined style with floating labels
- **Icons**: Lucide icons, 24px standard size
- **Spacing**: 8px base grid (multiples: 8, 16, 24, 32, 48)

---

## 📊 State Management

### Provider Pattern

```dart
// Main Providers
- AuthProvider: User authentication state
- FoodProvider: Food items and categories
- CartProvider: Shopping cart management
- OrderProvider: Order tracking and history
- AdminProvider: Admin dashboard data
- DineInProvider: Table ordering state
- LanguageProvider: App localization
- WebSocketProvider: Real-time updates
```

### State Flow
```
UI Widget → Provider → Repository → API Service → Backend
     ↑                                              |
     └────────────── Response ──────────────────────┘
```

---

## 🔌 WebSocket Events

### Real-time Order Updates
```javascript
// Client emits
'join_order', orderId      // Subscribe to order updates
'leave_order', orderId     // Unsubscribe

// Server emits
'order_status_update', { orderId, status, timestamp }
'driver_assigned', { orderId, driverInfo }
'driver_location', { orderId, location }
```

### Admin Dashboard
```javascript
// Server emits
'new_order', orderObject           // New order received
'order_cancelled', orderId         // Order cancelled
'daily_stats', statsObject         // Daily statistics update
```

---

## 💳 Payment Integration

### Supported Methods
1. **Telebirr** - Ethiopian mobile money
2. **M-Pesa** - Mobile money
3. **CBE Birr** - Commercial Bank of Ethiopia
4. **Cash on Delivery** - Pay at doorstep
5. **Credit/Debit Card** - Secure card payments

### Payment Flow
```
1. User selects payment method
2. Backend creates payment intent
3. User completes payment on gateway
4. Gateway calls webhook callback
5. Backend verifies payment
6. Order status updated to 'confirmed'
```

---

## 🚀 Deployment

### Backend Deployment (Render/Railway)
```bash
# Environment Variables
PORT=5001
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your_secret_key
JWT_REFRESH_SECRET=your_refresh_secret

# Payment Gateway Keys
TELEBIRR_API_KEY=...
MPESA_API_KEY=...
CBE_API_KEY=...

# Firebase
FIREBASE_SERVICE_ACCOUNT=...
```

### Frontend Build Commands
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 🧪 Testing

### Test Accounts
| Role | Email | Password |
|------|-------|----------|
| Customer | user@foodiego.com | user123 |
| Pizza Admin | pizza@foodiego.com | admin123 |
| Burger Admin | burger@foodiego.com | admin123 |
| Habesha Admin | habesha@foodiego.com | admin123 |
| Sweets Admin | sweets@foodiego.com | admin123 |

### API Testing
```bash
# Using curl
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@foodiego.com","password":"user123"}'
```

---

## 🔒 Security Features

1. **Rate Limiting** - 100 requests/minute per IP
2. **Input Sanitization** - XSS and NoSQL injection prevention
3. **Security Headers** - X-Content-Type-Options, X-Frame-Options, etc.
4. **Audit Logging** - All requests logged with timestamp, IP, user
5. **JWT Token Rotation** - Access + refresh token pattern
6. **Password Hashing** - bcrypt with salt rounds
7. **Role-Based Access Control** - Middleware checks for each endpoint

---

## 📈 Performance Optimizations

### Frontend
- Image lazy loading with cached_network_image
- Pagination for food/restaurant lists
- Debounced search queries
- Optimistic UI updates
- Skeleton loaders for better perceived performance

### Backend
- MongoDB indexing on frequently queried fields
- Compression middleware (gzip)
- Response caching for static data
- Database connection pooling

---

## 🐛 Troubleshooting

### Common Issues

**Backend won't start:**
- Check MongoDB connection string
- Verify PORT is not in use
- Ensure all environment variables are set

**Frontend can't connect to backend:**
- Update `API_BASE_URL` in constants
- For Android emulator: use `10.0.2.2`
- For iOS simulator: use `localhost`
- For physical device: use computer's IP

**Images not loading:**
- Check internet permission in AndroidManifest.xml
- Verify image URLs are accessible

---

## 📞 Support

For technical support or feature requests:
- Email: support@foodiego.com
- GitHub Issues: [github.com/muktarbdulkader/FoodieGo](https://github.com/muktarbdulkader/FoodieGo)

---

## 📄 License

MIT License - Open for commercial and personal use.

---

**Last Updated:** May 2026
**Version:** 1.0.0
**Maintained by:** Muktar Abdulkader
