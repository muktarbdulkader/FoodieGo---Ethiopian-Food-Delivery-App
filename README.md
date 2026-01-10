# FoodieGo 🍽️  
**Production-Ready Ethiopian Food Delivery Platform**

## ✨ **Key Features**

### 📱 **Customer Application**
- **Secure Authentication** – Register/login with email/password
- **Intuitive Browsing** – Explore foods by restaurant/hotel categories
- **Detailed Food Pages** – Complete with ratings, preparation time, calorie information, and reviews
- **Smart Shopping Cart** – Real-time quantity adjustments and total calculation
- **Automatic Location Detection** – Seamless delivery address setup
- **Localized Payments** – Support for Telebirr, M-Pesa, CBE Birr, Cash, and Card
- **Live Order Tracking** – Real-time status updates from kitchen to doorstep
- **Order History** – Complete purchase records
- **Profile Management** – Update personal information and preferences
- **Modern Animated UI** – Smooth transitions and engaging user experience

### 🛠️ **Admin Portal** (Accessible at `/admin`)
- **Comprehensive Dashboard** – Real-time sales analytics and performance metrics
- **Revenue Analytics** – Track earnings in Ethiopian Birr (ETB)
- **Menu Management** – Full CRUD operations for food items
- **Order Processing** – Update status and manage deliveries
- **Data Isolation** – Each admin only sees data from their assigned hotel/restaurant

### ⚙️ **Backend Capabilities**
- **Multi-Vendor Architecture** – Support for multiple restaurants/hotels
- **Rating System** – Customer reviews and food ratings
- **Promotional Engine** – Discount codes and special offers
- **Order Lifecycle** – Complete tracking with delivery status
- **Secure Authentication** – JWT tokens with bcrypt password hashing
- **Role-Based Access Control** – Distinct permissions for users and admins

## 🏗️ **Technology Architecture**

| **Component**  | **Technology**                              |
|----------------|---------------------------------------------|
| **Frontend**   | Flutter 3.5+ with Provider state management |
| **Backend**    | Node.js with Express.js framework           |
| **Database**   | MongoDB for flexible data modeling          |
| **Authentication** | JWT tokens with bcryptjs hashing         |
| **Location Services** | Geolocator and Geocoding APIs          |
| **State Management** | Provider pattern for efficient data flow |

## 🚀 **Quick Start Guide**

### **Backend Setup**
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Seed database with sample data
npm run seed

# Start development server (port 5001)
npm run dev
```

### **Frontend Setup**
```bash
# Navigate to frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# Run on preferred platform
flutter run -d edge      # Web browser
flutter run -d android   # Android device/emulator
flutter run -d ios       # iOS simulator (macOS only)
```

### **Android Emulator Configuration**
Update `frontend/lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:5001/api';
```

## 👥 **Test Credentials**

| **Role** | **Email** | **Password** | **Assigned Hotel** |
|----------|-----------|--------------|-------------------|
| Regular User | `user@foodiego.com` | `user123` | N/A |
| Restaurant Admin | `pizza@foodiego.com` | `admin123` | Pizza Palace |
| Restaurant Admin | `burger@foodiego.com` | `admin123` | Burger Barn |
| Restaurant Admin | `habesha@foodiego.com` | `admin123` | Habesha Kitchen |
| Restaurant Admin | `sweets@foodiego.com` | `admin123` | Sweet Treats |

**🔐 Admin Registration Code:** `FOODIEGO_ADMIN_2024`

## 💰 **Supported Payment Methods**
- **Telebirr** – Mobile money
- **M-Pesa** – Mobile money
- **CBE Birr** – Bank transfer
- **Cash on Delivery** – Pay when food arrives
- **Credit/Debit Card** – Secure card payments

## 📱 **Application Access Points**

| **URL Path** | **Audience** | **Purpose** |
|--------------|--------------|-------------|
| `/` | Customers | Main food ordering interface |
| `/admin` | Restaurant Administrators | Business management portal |

## 📦 **Production Build Instructions**

### **Android APK**
```bash
cd frontend
flutter build apk --release
```

### **Android App Bundle (Google Play Store)**
```bash
cd frontend
flutter build appbundle --release
```

### **iOS Application** (requires macOS)
```bash
cd frontend
flutter build ios --release
```

### **Web Deployment**
```bash
cd frontend
flutter build web --release
```

## 📁 **Project Structure**

```
foodiego/
├── backend/
│   ├── src/
│   │   ├── config/       # Database configuration
│   │   ├── controllers/  # API request handlers
│   │   ├── middlewares/  # Authentication and validation
│   │   ├── models/       # MongoDB schema definitions
│   │   ├── routes/       # API endpoint definitions
│   │   └── utils/        # Helper functions and seed data
│   ├── package.json      # Dependencies and scripts
│   └── .env.example      # Environment variables template
│
└── frontend/
    └── lib/
        ├── core/         # App constants, themes, utilities
        ├── data/         # Data models, API services, repositories
        ├── presentation/ # UI pages and widgets
        └── state/        # Provider state management
```

## 🎯 **Sample Data Overview**
The database seeding script automatically generates:
- **4 Diverse Restaurants** – Italian, American, Ethiopian, and dessert specialties
- **Curated Menu Items** – Each with realistic ratings, calorie counts, and prep times
- **Active Promotions** – Discount codes and special offers
- **Test Accounts** – Ready-to-use user and admin profiles

## 📊 **Key Performance Indicators**
- Real-time revenue tracking
- Order volume analytics
- Customer satisfaction metrics
- Delivery efficiency monitoring

## 🔒 **Security Features**
- Encrypted password storage
- JWT token-based authentication
- Role-based access control
- Input validation and sanitization
- Secure payment processing

## 🌐 **Localization Ready**
- Ethiopian payment integration
- Local currency (ETB) support
- Geocoding optimized for Ethiopian addresses

## 📄 **License**
MIT License – Open for commercial and personal use.

---

**💡 Pro Tip:** For the best development experience, run the backend server first, then launch the Flutter application. Ensure MongoDB is running locally or update the connection string for cloud databases.

**🎯 Success Metric:** FoodieGo is designed to handle hundreds of concurrent orders while providing sub-second response times for critical operations.
 Built build\app\outputs\flutter-apk\app-release.apk      

Built build\app\outputs\flutter-apk\app-release.apk   