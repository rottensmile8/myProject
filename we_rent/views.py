from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from pymongo import MongoClient
from django.contrib.auth.hashers import make_password, check_password
from db.mongodb import users_collection, vehicles_collection, bookings_collection, notifications_collection
import json
from django.http import JsonResponse
from bson import ObjectId
from datetime import datetime, timedelta, timezone
from .models import User


def home(request):
    return JsonResponse({"message": "Welcome to WeRent API!"})


@api_view(['POST'])
def signup(request):
    try:
        data = request.data
        email = data.get("email")
        password = data.get("password")
        full_name = data.get("fullName")
        role = data.get("role")

        if not email or not password or not full_name or not role:
            return Response({"error": "All fields are required"}, status=400)

        # Check if user already exists
        if users_collection.find_one({"email": email}):
            return Response({"error": "User already exists"}, status=400)

        # Hash the password
        hashed_password = make_password(password)

        user = {
            "fullName": full_name,
            "email": email,
            "password": hashed_password,
            "role": role,
            "isActive": False,  
        }

        # Insert user into MongoDB
        result = users_collection.insert_one(user)
        user_id = str(result.inserted_id)

        # create in Django SQL database for Admin Panel visibility
        User.objects.create(
            fullName=full_name,
            email=email,
            role=role,
            isActive=False  
        )

        # Return success with user data
        return Response({
            "message": "User registered successfully",
            "fullName": full_name,
            "email": email,
            "role": role,
            "_id": user_id,
            "isActive": False
        }, status=201)

    except Exception as e:
        print(f"Signup error: {str(e)}")
        return Response({"error": f"Server error: {str(e)}"}, status=500)


@api_view(['POST'])
def login_user(request):
    try:
        data = request.data
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return Response({"error": "Email and password are required"}, status=400)

        user = users_collection.find_one({"email": email})
        if not user:
            return Response({"error": "User not found"}, status=404)

        if not check_password(password, user['password']):
            return Response({"message": "Invalid credentials"}, status=401)

        # CHECK Admin Approval Status from Django SQL Database
        try:
            sql_user = User.objects.get(email=email)
            is_active = sql_user.isActive
        except User.DoesNotExist:
            sql_user = User.objects.create(
                fullName=user['fullName'],
                email=user['email'],
                role=user['role'],
                isActive=True  
            )
            is_active = True

        # SYNC: Update MongoDB with the current isActive status from SQL
        users_collection.update_one(
            {"email": email},
            {"$set": {"isActive": is_active}}
        )

        # Return user data to Flutter
        return Response({
            "fullName": user['fullName'],
            "email": user['email'],
            "role": user['role'],
            "_id": str(user['_id']),
            "isActive": is_active
        })

    except Exception as e:
        print(f"Login error: {str(e)}")
        return Response({"error": f"Server error: {str(e)}"}, status=500)


# Vehicle APIs
@api_view(['GET', 'POST'])
def vehicles(request):
    owner_id = request.query_params.get('owner_id')

    if request.method == 'GET':
        try:
            if owner_id:
                vehicles = list(vehicles_collection.find(
                    {"ownerId": owner_id}))
            else:
                vehicles = list(vehicles_collection.find())

            for vehicle in vehicles:
                vehicle['_id'] = str(vehicle['_id'])
                if 'createdAt' in vehicle:
                    vehicle['createdAt'] = vehicle['createdAt'].isoformat() if isinstance(
                        vehicle['createdAt'], datetime) else vehicle['createdAt']
                try:
                    owner = users_collection.find_one({"_id": ObjectId(
                        vehicle.get('ownerId', ''))}) if vehicle.get('ownerId') else None
                    vehicle['ownerName'] = owner.get(
                        'fullName', 'Unknown') if owner else 'Unknown'
                except Exception:
                    vehicle['ownerName'] = 'Unknown'

            return Response(vehicles)
        except Exception as e:
            print(f"Get vehicles error: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=500)

    elif request.method == 'POST':
        try:
            data = request.data
            owner_id = data.get('ownerId')
            category = data.get('category')
            name = data.get('name')
            brand = data.get('brand')
            model_year = data.get('modelYear')
            price_per_day = data.get('pricePerDay')
            fuel_type = data.get('fuelType')
            transmission = data.get('transmission')
            pickup_location = data.get('pickupLocation')
            image_base64 = data.get('imageBase64')  

            if not all([owner_id, category, name, brand, model_year, price_per_day, pickup_location]):
                return Response({"error": "All fields are required"}, status=400)

            vehicle = {
                "ownerId": owner_id,
                "category": category,
                "name": name,
                "brand": brand,
                "modelYear": model_year,
                "pricePerDay": price_per_day,
                "fuelType": fuel_type if fuel_type else "petrol",
                "transmission": transmission if transmission else "manual",
                "pickupLocation": pickup_location,
                "isAvailable": True,
                "createdAt": datetime.now()
            }
            if image_base64:
                vehicle["imageBase64"] = image_base64

            result = vehicles_collection.insert_one(vehicle)
            vehicle['_id'] = str(result.inserted_id)
            vehicle['createdAt'] = vehicle['createdAt'].isoformat()

            return Response(vehicle, status=201)
        except Exception as e:
            print(f"Add vehicle error: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=500)


@api_view(['GET', 'PUT', 'DELETE'])
def vehicle_detail(request, vehicle_id):
    try:
        vehicle = vehicles_collection.find_one({"_id": ObjectId(vehicle_id)})
        if not vehicle:
            return Response({"error": "Vehicle not found"}, status=404)

        if request.method == 'GET':
            vehicle['_id'] = str(vehicle['_id'])
            if 'createdAt' in vehicle:
                vehicle['createdAt'] = vehicle['createdAt'].isoformat()
            return Response(vehicle)

        elif request.method == 'PUT':
            data = request.data
            update_data = {}

            for key in ['category', 'name', 'brand', 'modelYear', 'pricePerDay',
                        'fuelType', 'transmission', 'pickupLocation', 'isAvailable',
                        'imageBase64']:
                if key in data:
                    update_data[key] = data[key]

            vehicles_collection.update_one(
                {"_id": ObjectId(vehicle_id)},
                {"$set": update_data}
            )

            vehicle = vehicles_collection.find_one(
                {"_id": ObjectId(vehicle_id)})
            vehicle['_id'] = str(vehicle['_id'])
            if 'createdAt' in vehicle:
                vehicle['createdAt'] = vehicle['createdAt'].isoformat()
            return Response(vehicle)

        elif request.method == 'DELETE':
            vehicles_collection.delete_one({"_id": ObjectId(vehicle_id)})
            return Response({"message": "Vehicle deleted successfully"})

    except Exception as e:
        print(f"Vehicle detail error: {str(e)}")
        return Response({"error": f"Server error: {str(e)}"}, status=500)


# Booking APIs
from rest_framework.decorators import api_view
from rest_framework.response import Response
from bson import ObjectId
from datetime import datetime, timezone
from db.mongodb import vehicles_collection, bookings_collection, notifications_collection, users_collection

@api_view(['GET', 'POST'])
def bookings(request):
    owner_id = request.query_params.get('owner_id')
    renter_id = request.query_params.get('renter_id')

    if request.method == 'GET':
        try:
            # Determine filter
            if owner_id:
                # Find all vehicles owned by this user first
                owner_vehicles = list(vehicles_collection.find({"ownerId": owner_id}))
                vehicle_ids = [str(v['_id']) for v in owner_vehicles]
                query = {"vehicleId": {"$in": vehicle_ids}}
            elif renter_id:
                query = {"renterId": renter_id}
            else:
                query = {}

            bookings_list = list(bookings_collection.find(query).sort("createdAt", -1))

            for booking in bookings_list:
                booking['_id'] = str(booking['_id'])
                
                # IMPORTANT: Fetch the vehicle details to get the image
                vehicle = vehicles_collection.find_one({"_id": ObjectId(booking['vehicleId'])})
                if vehicle:
                    # Explicitly map the image and other metadata
                    booking['vehicleImageBase64'] = vehicle.get('imageBase64', "")
                    booking['vehicleName'] = vehicle.get('name', "Unknown Vehicle")
                    booking['vehicleCategory'] = vehicle.get('category', "car")
                
                # Format dates for Flutter
                for date_field in ['createdAt', 'startDate', 'endDate']:
                    if date_field in booking and isinstance(booking[date_field], datetime):
                        booking[date_field] = booking[date_field].isoformat()

            return Response(bookings_list)
        except Exception as e:
            return Response({"error": str(e)}, status=500)

    elif request.method == 'POST':
        try:
            data = request.data
            vehicle_id = data.get('vehicleId')
            renter_id = data.get('renterId')
            total_price = data.get('totalPrice')

            vehicle = vehicles_collection.find_one({"_id": ObjectId(vehicle_id)})
            renter = users_collection.find_one({"_id": ObjectId(renter_id)})

            if not vehicle or not renter:
                return Response({"error": "Vehicle or User not found"}, status=404)

            # Create Booking
            booking = {
                "vehicleId": vehicle_id,
                "vehicleName": vehicle.get('name'),
                "vehicleCategory": vehicle.get('category'),
                "renterId": renter_id,
                "renterName": renter.get('fullName'),
                "startDate": datetime.fromisoformat(data['startDate'].replace('Z', '+00:00')),
                "endDate": datetime.fromisoformat(data['endDate'].replace('Z', '+00:00')),
                "totalPrice": total_price,
                "status": "confirmed",
                "createdAt": datetime.now()
            }

            result = bookings_collection.insert_one(booking)
            
            # Update Vehicle availability
            vehicles_collection.update_one(
                {"_id": ObjectId(vehicle_id)},
                {"$set": {"isAvailable": False}}
            )

            # --- DUAL NOTIFICATIONS ---
            # To Owner
            notifications_collection.insert_one({
                "userId": vehicle['ownerId'],
                "title": "New Booking",
                "message": f"{renter['fullName']} rented your {vehicle['name']}.",
                "type": "success", "isRead": False, "createdAt": datetime.now()
            })
            # To Renter
            notifications_collection.insert_one({
                "userId": renter_id,
                "title": "Booking Confirmed",
                "message": f"You've successfully rented {vehicle['name']}.",
                "type": "info", "isRead": False, "createdAt": datetime.now()
            })

            return Response({"message": "Booked successfully", "id": str(result.inserted_id)}, status=201)
        except Exception as e:
            return Response({"error": str(e)}, status=500)

# @api_view(['PUT', 'DELETE'])
# def booking_detail(request, booking_id):
#     try:
#         booking = bookings_collection.find_one({"_id": ObjectId(booking_id)})
#         if not booking: return Response({"error": "Not found"}, status=404)

#         if request.method == 'PUT':
#             data = request.data
#             update_data = {}

#             if 'status' in data:
#                 new_status = data['status']
#                 update_data['status'] = new_status
                
#                 # Make vehicle available if trip ends
#                 if new_status in ['completed', 'cancelled']:
#                     vehicles_collection.update_one(
#                         {"_id": ObjectId(booking['vehicleId'])},
#                         {"$set": {"isAvailable": True}}
#                     )

#             if 'refundAmount' in data:
#                 update_data['refundAmount'] = float(data['refundAmount'])

#             bookings_collection.update_one({"_id": ObjectId(booking_id)}, {"$set": update_data})
#             return Response({"message": "Updated"})

#         elif request.method == 'DELETE':
#             bookings_collection.delete_one({"_id": ObjectId(booking_id)})
#             return Response({"message": "Deleted"})

#     except Exception as e:
#         return Response({"error": str(e)}, status=500)

# Django views.py
# Django views.py
@api_view(['GET', 'PUT', 'DELETE'])
def booking_detail(request, booking_id):
    try:
        booking = bookings_collection.find_one({"_id": ObjectId(booking_id)})
        if not booking:
            return Response({"error": "Booking not found"}, status=404)

        if request.method == 'PUT':
            data = request.data
            new_status = data.get('status')  # Expected: 'completed' or 'cancelled'
            
            # 1. Fetch Vehicle and Party Details
            vehicle = vehicles_collection.find_one({"_id": ObjectId(booking['vehicleId'])})
            if not vehicle:
                return Response({"error": "Vehicle not found"}, status=404)

            owner_id = str(vehicle['ownerId'])
            renter_id = str(booking['renterId'])
            vehicle_name = vehicle.get('name', 'Vehicle')

            # 2. Update Booking Status in MongoDB
            bookings_collection.update_one(
                {"_id": ObjectId(booking_id)}, 
                {"$set": {"status": new_status}}
            )

            # 3. Process Return/Cancellation Logic
            if new_status in ['completed', 'cancelled']:
                # Free the vehicle for the next renter
                vehicles_collection.update_one(
                    {"_id": ObjectId(booking['vehicleId'])},
                    {"$set": {"isAvailable": True}}
                )

                # Set customized messages
                if new_status == 'completed':
                    owner_title, owner_msg = "Vehicle Returned", f"{booking['renterName']} has returned your {vehicle_name}. The vehicle is available for booking"
                    renter_title, renter_msg = "Return Successful", f"You have successfully returned the {vehicle_name}. Thank you!"
                else: # cancelled
                    owner_title, owner_msg = "Booking Cancelled", f"The booking for your {vehicle_name} was cancelled. The vehicle is available for booking"
                    renter_title, renter_msg = "Trip Cancelled", f"Your booking for {vehicle_name} has been cancelled."

                # 4. SEND DUAL NOTIFICATIONS
                # To Owner
                notifications_collection.insert_one({
                    "userId": owner_id,
                    "title": owner_title,
                    "message": owner_msg,
                    "type": "info", "isRead": False, "createdAt": datetime.now()
                })
                # To Renter
                notifications_collection.insert_one({
                    "userId": renter_id,
                    "title": renter_title,
                    "message": renter_msg,
                    "type": "info", "isRead": False, "createdAt": datetime.now()
                })

            return Response({"message": f"Booking {new_status} successfully"})

    except Exception as e:
        return Response({"error": str(e)}, status=500)
    
@api_view(['GET'])
def sync_users(request):
    try:    
        mongo_users = list(users_collection.find())
        synced_count = 0
        for m_user in mongo_users:
            if not User.objects.filter(email=m_user['email']).exists():
                User.objects.create(
                    fullName=m_user.get('fullName', 'Unknown'),
                    email=m_user['email'],
                    role=m_user.get('role', 'renter'),
                    isActive=True  
                )

            if 'isActive' not in m_user:
                users_collection.update_one(
                    {"email": m_user['email']},
                    {"$set": {"isActive": True}}
                )
            synced_count += 1
        return Response({"message": f"Successfully synced {synced_count} users to Django Admin."})
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['GET', 'DELETE'])
def notifications(request):
    user_id = request.query_params.get('user_id')
    notification_id = request.query_params.get('notification_id')

    if request.method == 'GET':
        if not user_id:
            return Response({"error": "user_id required"}, status=400)
        notifs = list(notifications_collection.find({"userId": user_id}).sort("createdAt", -1))
        for n in notifs:
            n['_id'] = str(n['_id'])
            if isinstance(n.get('createdAt'), datetime):
                n['createdAt'] = n['createdAt'].isoformat()
        return Response(notifs)

    elif request.method == 'DELETE':
        try:
            if notification_id:
                notifications_collection.delete_one({"_id": ObjectId(notification_id)})
                return Response({"message": "Deleted notification"})
            elif user_id:
                # Clear all for owner/renter
                notifications_collection.delete_many({"userId": user_id})
                return Response({"message": "Cleared all notifications"})
            return Response({"error": "Missing ID parameters"}, status=400)
        except Exception as e:
            return Response({"error": str(e)}, status=500)
