from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from pymongo import MongoClient
from django.contrib.auth.hashers import make_password, check_password
from db.mongodb import users_collection  # Fixed import to point to 'weRentDB'
import json
from django.http import JsonResponse


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
        }

        # Insert user into MongoDB
        result = users_collection.insert_one(user)

        # Return success with user data
        return Response({
            "message": "User registered successfully",
            "fullName": full_name,
            "email": email,
            "role": role,
            "_id": str(result.inserted_id)
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

        # Return user data to Flutter
        return Response({
            "fullName": user['fullName'],
            "email": user['email'],
            "role": user['role'],
            "_id": str(user['_id'])
        })

    except Exception as e:
        # Log the error for debugging
        print(f"Login error: {str(e)}")
        return Response({"error": f"Server error: {str(e)}"}, status=500)
