from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError
import sys

# Connection String with 5-second timeout for server selection
client = MongoClient("mongodb://localhost:27017", serverSelectionTimeoutMS=5000)
db = client["weRentDB"]          # Database name
users_collection = db["users"]   # Collection name
vehicles_collection = db["vehicles"] 
bookings_collection = db["bookings"]
notifications_collection = db["notifications"]

# Verify connection
try:
    # Attempt a simple admin command to check connectivity
    client.admin.command('ping')
    print("MongoDB connected successfully")
except ServerSelectionTimeoutError:
    print("❌ Critical: Could not connect to MongoDB server! Please ensure it is running.")
    # In a production environment, you might log this more formally
except Exception as e:
    print(f"❌ MongoDB error: {e}")
