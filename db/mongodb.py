from pymongo import MongoClient

# Connection String
client = MongoClient("mongodb://localhost:27017")
db = client["weRentDB"]          # Database name
users_collection = db["users"]   # Collection name
vehicles_collection = db["vehicles"] 
bookings_collection = db["bookings"]
notifications_collection = db["notifications"]

print("MongoDB connected successfully")
