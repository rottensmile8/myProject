# WeRent - MongoDB Connection Setup Guide

## 🚨 SocketException Error Fix

If you're seeing `SocketException` or connection errors, follow these steps:

### Prerequisites

1. **MongoDB Must Be Running**

   - Open MongoDB Compass
   - Connect to: `mongodb://localhost:27017`
   - You should see the `weRentDB` database

2. **Django Server Must Be Running**

   ```bash
   cd /Users/rakeshgurung/my_project
   python manage.py runserver
   ```

3. **Required Python Packages**
   ```bash
   pip install pymongo django djangorestframework django-cors-headers
   ```

## 🔧 Setup Instructions

### Step 1: Start MongoDB

```bash
# Option 1: Using MongoDB Compass
# 1. Open MongoDB Compass
# 2. Click "New Connection"
# 3. Enter: mongodb://localhost:27017
# 4. Click "Connect"

# Option 2: Using Terminal (if MongoDB is installed)
mongod --dbpath /path/to/your/data/directory
```

### Step 2: Verify MongoDB Connection

1. In MongoDB Compass, you should see:
   - Database: `weRentDB`
   - Collection: `users`

### Step 3: Start Django Backend

```bash
cd /Users/rakeshgurung/my_project
python manage.py runserver
```

**Expected Output:**

```
System check identified no issues (0 silenced).
June 15, 2025 - 12:00:00
Django version 5.2.8, using settings 'backend.settings'
Starting development server at http://127.0.0.1:8000/
```

### Step 4: Test the Backend

Open a new terminal and test:

```bash
# Test Signup
curl -X POST http://127.0.0.1:8000/api/signup/ \
  -H "Content-Type: application/json" \
  -d '{"fullName": "Test User", "email": "test@example.com", "password": "password123", "role": "renter"}'

# Test Login
curl -X POST http://127.0.0.1:8000/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

### Step 5: Run Flutter App

```bash
cd /Users/rakeshgurung/my_project/werent
flutter run
```

## 📋 Error Messages Guide

The app now displays user-friendly error messages:

| Error Type          | User-Friendly Message                                                                                                           |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| SocketException     | "Cannot connect to server. Please ensure:\n1. MongoDB is running\n2. Django server is running\n3. You have internet connection" |
| User already exists | "An account with this email already exists. Please login or use a different email."                                             |
| User not found      | "No account found with this email. Please signup first."                                                                        |
| Invalid credentials | "Incorrect password. Please try again."                                                                                         |
| All fields required | "Please fill in all required fields."                                                                                           |
| Role mismatch       | "You are trying to login as renter but your account is registered as owner. Please select the correct role."                    |

## 🔍 Troubleshooting

### Issue: "Cannot connect to server"

**Solutions:**

1. Check if MongoDB Compass is connected
2. Restart MongoDB Compass
3. Restart Django server
4. Check if port 27017 is blocked

### Issue: "User already exists"

**Solutions:**

1. Use a different email address
2. Login with the existing account

### Issue: "Invalid credentials"

**Solutions:**

1. Check if you're using the correct password
2. Make sure you're selecting the correct role (Renter/Owner)

### Issue: Login works but immediately logs out

**Solutions:**

1. Check Django console for errors
2. Verify MongoDB is connected
3. Restart both servers

## 📁 Project Structure

```
/Users/rakeshgurung/my_project/
├── db/
│   └── mongodb.py              # MongoDB connection config
├── backend/
│   ├── urls.py                 # URL routing (includes we_rent.urls)
│   └── views.py                # API endpoints with error handling
├── we_rent/
│   ├── urls.py                 # /signup/ and /login/ endpoints
│   └── views.py                # MongoDB operations
└── wont/
    └── lib/
        ├── main.dart           # App routes and navigation
        ├── controllers/
        │   └── auth_controller.dart  # Auth logic with error handling
        ├── auth/
        │   ├── login_screen.dart
        │   ├── signup_screen.dart
        │   ├── renter_dashboard.dart
        │   └── owner_dashboard.dart
        └── models/
            └── user_model.dart
```

## 🗄️ MongoDB Data Structure

### Users Collection

```json
{
  "_id": ObjectId("..."),
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "hashed_password",
  "role": "renter"  // or "owner"
}
```

## ✅ Final Checklist

Before running the app, confirm:

- [ ] MongoDB Compass connected to `mongodb://localhost:27017`
- [ ] `weRentDB` database exists
- [ ] Django server running (`python manage.py runserver`)
- [ ] No errors in Django console
- [ ] Flutter app can connect to `http://127.0.0.1:8000/api/`

## 📞 If Issues Persist

1. **Check Django Console** for error messages
2. **Check MongoDB Compass** for data persistence
3. **Restart everything:**

   ```bash
   # Terminal 1: Restart MongoDB
   # (Just reopen MongoDB Compass if it's already installed)

   # Terminal 2: Restart Django
   cd /Users/rakeshgurung/my_project
   pkill -f "python manage.py runserver"
   python manage.py runserver

   # Terminal 3: Restart Flutter
   cd /Users/rakeshgurung/my_project/werent
   flutter run
   ```

4. **Test with curl** to isolate the issue:
   ```bash
   curl -X POST http://127.0.0.1:8000/api/signup/ \
     -H "Content-Type: application/json" \
     -d '{"fullName": "Test", "email": "test@test.com", "password": "test123", "role": "renter"}'
   ```

This guide should help you get the MongoDB connection working properly!
