from pymongo import MongoClient
 
# Connection String
client = MongoClient("mongodb://localhost:27017" )
db = client["weRentDB"]          # Database name
users_collection = db["users"]   # Collection name

print("MongoDB connected successfully")
