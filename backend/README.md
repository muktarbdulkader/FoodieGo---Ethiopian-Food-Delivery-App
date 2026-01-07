# Food Delivery API - Node.js Backend

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure MongoDB is running locally on port 27017

3. Start the server:
```bash
npm run dev
```

The API will be available at `http://localhost:5000/api`

## API Endpoints

### Auth
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Foods
- `GET /api/foods` - Get all foods (public)
- `POST /api/foods` - Create food (admin/restaurant only)

### Orders (protected)
- `GET /api/orders` - Get user's orders
- `POST /api/orders` - Create new order

## Project Structure

```
src/
├── config/        # Database configuration
├── controllers/   # Route handlers
├── middlewares/   # Auth and error middleware
├── models/        # Mongoose schemas
├── routes/        # API routes
└── utils/         # JWT and password utilities
```
