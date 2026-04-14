from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from pymongo import MongoClient
from django.contrib.auth.hashers import make_password, check_password
from db.mongodb import users_collection, vehicles_collection, bookings_collection, notifications_collection
import json
from django.http import JsonResponse
from bson import ObjectId
from datetime import datetime
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
            "isActive": False,  # Store in MongoDB as well
        }

        # Insert user into MongoDB
        result = users_collection.insert_one(user)
        user_id = str(result.inserted_id)

        # ALSO create in Django SQL database for Admin Panel visibility
        User.objects.create(
            fullName=full_name,
            email=email,
            role=role,
            isActive=False  # New users are inactive by default
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
        # Log the error for debugging
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

        # check hashed password
        from django.contrib.auth.hashers import check_password
        if not check_password(password, user['password']):
            return Response({"message": "Invalid credentials"}, status=401)

        # CHECK Admin Approval Status from Django SQL Database
        try:
            sql_user = User.objects.get(email=email)
            is_active = sql_user.isActive
        except User.DoesNotExist:
            # If user exists in Mongo but not SQL, sync them now
            sql_user = User.objects.create(
                fullName=user['fullName'],
                email=user['email'],
                role=user['role'],
                isActive=True  # Existing users are active by default
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
        # Log the error for debugging
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

            # Convert ObjectId to string for each vehicle
            for vehicle in vehicles:
                vehicle['_id'] = str(vehicle['_id'])
                if 'createdAt' in vehicle:
                    vehicle['createdAt'] = vehicle['createdAt'].isoformat() if isinstance(
                        vehicle['createdAt'], datetime) else vehicle['createdAt']
                # Attach owner's name
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
            image_base64 = data.get('imageBase64')  # optional vehicle photo

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
@api_view(['GET', 'POST'])
def bookings(request):
    owner_id = request.query_params.get('owner_id')
    renter_id = request.query_params.get('renter_id')

    if request.method == 'GET':
        try:
            if owner_id:
                # Get all vehicles owned by this owner
                owner_vehicles = list(
                    vehicles_collection.find({"ownerId": owner_id}))
                vehicle_ids = [v['_id'] for v in owner_vehicles]

                # Get bookings for these vehicles
                bookings = list(bookings_collection.find(
                    {"vehicleId": {"$in": [str(v) for v in vehicle_ids]}}))
            elif renter_id:
                bookings = list(bookings_collection.find(
                    {"renterId": renter_id}))
            else:
                bookings = list(bookings_collection.find())

            # Convert ObjectId to string and attach vehicle image to each booking
            for booking in bookings:
                booking['_id'] = str(booking['_id'])
                if 'createdAt' in booking:
                    booking['createdAt'] = booking['createdAt'].isoformat()
                if 'startDate' in booking:
                    booking['startDate'] = booking['startDate'].isoformat()
                if 'endDate' in booking:
                    booking['endDate'] = booking['endDate'].isoformat()
                # Attach vehicle details
                try:
                    vehicle = vehicles_collection.find_one(
                        {"_id": ObjectId(booking.get('vehicleId', ''))})
                    if vehicle:
                        booking['vehicleImageBase64'] = vehicle.get(
                            'imageBase64')
                        booking['vehicleName'] = vehicle.get('name')
                        booking['vehicleCategory'] = vehicle.get('category')
                    else:
                        booking['vehicleImageBase64'] = None
                except Exception:
                    booking['vehicleImageBase64'] = None

            return Response(bookings)
        except Exception as e:
            print(f"Get bookings error: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=500)

    elif request.method == 'POST':
        try:
            data = request.data
            vehicle_id = data.get('vehicleId')
            renter_id = data.get('renterId')
            start_date = data.get('startDate')
            end_date = data.get('endDate')
            total_price = data.get('totalPrice')

            if not all([vehicle_id, renter_id, start_date, end_date, total_price]):
                return Response({"error": "All fields are required"}, status=400)

            # Get vehicle details
            vehicle = vehicles_collection.find_one(
                {"_id": ObjectId(vehicle_id)})
            if not vehicle:
                return Response({"error": "Vehicle not found"}, status=404)

            # Check if renter has existing active rental
            existing_active = bookings_collection.find_one({
                "renterId": renter_id,
                "status": "confirmed"
            })
            if existing_active:
                return Response({"error": "You already have an active rental. Please complete or cancel your current rental first."}, status=400)

            # Get renter details
            renter = users_collection.find_one({"_id": ObjectId(renter_id)})

            booking = {
                "vehicleId": vehicle_id,
                "vehicleName": vehicle.get('name', ''),
                "vehicleCategory": vehicle.get('category', 'car'),
                "renterId": renter_id,
                "renterName": renter.get('fullName', '') if renter else '',
                "renterEmail": renter.get('email', '') if renter else '',
                "startDate": datetime.fromisoformat(start_date.replace('Z', '+00:00')),
                "endDate": datetime.fromisoformat(end_date.replace('Z', '+00:00')),
                "totalPrice": total_price,
                "status": "pending",
                "createdAt": datetime.now()
            }

            result = bookings_collection.insert_one(booking)
            booking['_id'] = str(result.inserted_id)
            booking['createdAt'] = booking['createdAt'].isoformat()
            booking['startDate'] = booking['startDate'].isoformat()
            booking['endDate'] = booking['endDate'].isoformat()

            return Response(booking, status=201)
        except Exception as e:
            print(f"Add booking error: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=500)


@api_view(['GET', 'PUT', 'DELETE'])
def booking_detail(request, booking_id):
    try:
        booking = bookings_collection.find_one({"_id": ObjectId(booking_id)})
        if not booking:
            return Response({"error": "Booking not found"}, status=404)

        if request.method == 'GET':
            booking['_id'] = str(booking['_id'])
            for field in ['createdAt', 'startDate', 'endDate']:
                if field in booking and isinstance(booking[field], datetime):
                    booking[field] = booking[field].isoformat()
            return Response(booking)

        elif request.method == 'PUT':
            data = request.data
            update_data = {}

            if 'status' in data:
                new_status = data['status']
                update_data['status'] = new_status

                # Update vehicle availability
                vehicle_doc = vehicles_collection.find_one(
                    {"_id": ObjectId(booking['vehicleId'])})
                if vehicle_doc:
                    if new_status == 'confirmed':
                        vehicles_collection.update_one(
                            {"_id": ObjectId(booking['vehicleId'])},
                            {"$set": {"isAvailable": False}}
                        )
                    elif new_status in ['completed', 'cancelled']:
                        vehicles_collection.update_one(
                            {"_id": ObjectId(booking['vehicleId'])},
                            {"$set": {"isAvailable": True}}
                        )

                # Create notification for renter
                try:
                    if new_status in ['confirmed', 'cancelled']:
                        notifications_collection.insert_one({
                            "userId": booking['renterId'],
                            "title": "Booking Update",
                            "message": f"Your booking for {booking['vehicleName']} has been {new_status}.",
                            "type": "success" if new_status == 'confirmed' else "error",
                            "isRead": False,
                            "createdAt": datetime.now()
                        })
                except Exception as e:
                    print(f"Notification error: {str(e)}")

            if 'refundAmount' in data:
                update_data['refundAmount'] = data['refundAmount']

            if update_data:
                bookings_collection.update_one(
                    {"_id": ObjectId(booking_id)},
                    {"$set": update_data}
                )

            booking = bookings_collection.find_one(
                {"_id": ObjectId(booking_id)})
            booking['_id'] = str(booking['_id'])
            for field in ['createdAt', 'startDate', 'endDate']:
                if field in booking and isinstance(booking[field], datetime):
                    booking[field] = booking[field].isoformat()

            # Attach latest vehicle details
            try:
                vehicle = vehicles_collection.find_one(
                    {"_id": ObjectId(booking.get('vehicleId', ''))})
                if vehicle:
                    booking['vehicleImageBase64'] = vehicle.get('imageBase64')
                    booking['vehicleName'] = vehicle.get('name')
                    booking['vehicleCategory'] = vehicle.get('category')
            except Exception:
                pass

            return Response(booking)

        elif request.method == 'DELETE':
            bookings_collection.delete_one({"_id": ObjectId(booking_id)})
            return Response({"message": "Booking deleted successfully"})

    except Exception as e:
        print(f"Booking detail error: {str(e)}")
        return Response({"error": f"Server error: {str(e)}"}, status=500)


@api_view(['GET'])
def sync_users(request):
    """Temporary view to sync all MongoDB users to the Django Admin panel"""
    try:
        mongo_users = list(users_collection.find())
        synced_count = 0
        for m_user in mongo_users:
            # Sync to SQL if missing
            if not User.objects.filter(email=m_user['email']).exists():
                User.objects.create(
                    fullName=m_user.get('fullName', 'Unknown'),
                    email=m_user['email'],
                    role=m_user.get('role', 'renter'),
                    isActive=True  # Existing users are set to active
                )

            # Ensure isActive exists in MongoDB
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
            return Response({"error": "user_id is required"}, status=400)

        try:
            notifications = list(notifications_collection.find(
                {"userId": user_id}).sort("createdAt", -1))
            for n in notifications:
                n['_id'] = str(n['_id'])
                if 'createdAt' in n:
                    n['createdAt'] = n['createdAt'].isoformat() if isinstance(
                        n['createdAt'], datetime) else n['createdAt']
            return Response(notifications)
        except Exception as e:
            return Response({"error": str(e)}, status=500)

    elif request.method == 'DELETE':
        try:
            if notification_id:
                notifications_collection.delete_one(
                    {"_id": ObjectId(notification_id)})
                return Response({"message": "Notification deleted"})
            elif user_id:
                notifications_collection.delete_many({"userId": user_id})
                return Response({"message": "All notifications cleared"})
            return Response({"error": "notification_id or user_id required"}, status=400)
        except Exception as e:
            return Response({"error": str(e)}, status=500)
