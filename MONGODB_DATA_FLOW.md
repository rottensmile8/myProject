# MongoDB Data Storage and Login Flow

## Where User Data is Stored

### Database Location:

- **Database**: `weRentDB`
- **Collection**: `users`
- **Connection**: `mongodb://localhost:27017`

### Data Storage Details:

When a user signs up, their details are stored in MongoDB as follows:

```json
{
  "_id": ObjectId("..."),
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "hashed_password_string",
  "role": "renter"
}
```

## How Signup Works:

1. **Flutter App** sends signup request:

   ```dart
   http.post(
     Uri.parse('http://127.0.0.1:8000/api/signup/'),
     body: {
       "fullName": "John Doe",
       "email": "john@example.com",
       "password": "password123",
       "role": "renter"
     }
   )
   ```

2. **Django Backend** (`we_rent/views.py`):

   - Receives the request
   - Hashes the password using `make_password(password)`
   - Stores in MongoDB using `users_collection.insert_one(user)`
   - Returns success message

3. **MongoDB** stores the document in `weRentDB.users` collection

## How Login Works:

1. **Flutter App** sends login request:

   ```dart
   http.post(
     Uri.parse('http://127.0.0.1:8000/api/login/'),
     body: {
       "email": "john@example.com",
       "password": "password123"
     }
   )
   ```

2. **Django Backend** (`we_rent/views.py`):

   - Searches for user by email: `users_collection.find_one({"email": email})`
   - Checks password hash: `check_password(password, user['password'])`
   - Returns user data if successful

3. **Response** includes:
   ```json
   {
     "fullName": "John Doe",
     "email": "john@example.com",
     "role": "renter",
     "id": "user_object_id"
   }
   ```

## Viewing Stored Data in MongoDB Compass:

1. **Open MongoDB Compass**
2. **Connect** to: `mongodb://localhost:27017`
3. **Navigate** to:
   - Database: `weRentDB`
   - Collection: `users`
4. **View** all stored user documents

## Data Structure:

| Field      | Type     | Description                        |
| ---------- | -------- | ---------------------------------- |
| `_id`      | ObjectId | Unique identifier (auto-generated) |
| `fullName` | String   | User's full name                   |
| `email`    | String   | User's email (unique)              |
| `password` | String   | Hashed password                    |
| `role`     | String   | User role ("renter" or "owner")    |

## Example Workflow:

### 1. Signup:

```bash
curl -X POST http://127.0.0.1:8000/api/signup/ \
-H "Content-Type: application/json" \
-d '{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "renter"
}'
```

**Response**:

```json
{
  "message": "User registered successfully"
}
```

**In MongoDB Compass**:

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "pbkdf2_sha256$720000$...", // Hashed password
  "role": "renter"
}
```

### 2. Login:

```bash
curl -X POST http://127.0.0.1:8000/api/login/ \
-H "Content-Type: application/json" \
-d '{
  "email": "john@example.com",
  "password": "password123"
}'
```

**Response**:

```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "role": "renter",
  "id": "507f1f77bcf86cd799439011"
}
```

## Security Features:

1. **Password Hashing**: Uses Django's `make_password()` (PBKDF2 by default)
2. **Password Verification**: Uses Django's `check_password()`
3. **Email Unique**: Checks if email already exists before signup

## Troubleshooting:

### If signup fails:

- Check MongoDB is running
- Verify connection string in `db/mongodb.py`
- Check if `weRentDB` and `users` collection exist

### If login fails:

- Verify email exists in MongoDB
- Check password is correct (hashed passwords cannot be reversed)
- Ensure user role matches expected role in Flutter app

## Testing with MongoDB Compass:

1. **After signup**, open MongoDB Compass
2. **Navigate** to `weRentDB` → `users` collection
3. **Verify** the new user document appears
4. **Check** the password is hashed (not plain text)
5. **Use** the `_id` field for user identification in your app
