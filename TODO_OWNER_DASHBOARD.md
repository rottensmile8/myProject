# Owner Dashboard Implementation Plan

## Backend Updates

- [x] 1. Update `we_rent/views.py` - Add vehicle and booking API endpoints
- [x] 2. Update `we_rent/urls.py` - Add routes for vehicles and bookings

## Flutter Updates

- [x] 3. Create `werent/lib/models/vehicle_model.dart` - Vehicle data model
- [x] 4. Create `werent/lib/controllers/vehicle_controller.dart` - API calls for vehicles
- [x] 5. Create `werent/lib/auth/add_vehicle.dart` - Add Vehicle screen with category selection
- [x] 6. Create `werent/lib/auth/my_vehicles.dart` - My Vehicles screen to manage vehicles
- [x] 7. Create `werent/lib/auth/bookings.dart` - Bookings screen to view rentals
- [x] 8. Modify `werent/lib/auth/owner_dashboard.dart` - Show only 3 icons with navigation
- [x] 9. Update `werent/lib/main.dart` - Add routes for new screens

## Additional Updates

- [x] 10. Create `werent/lib/models/booking_model.dart` - Booking data model
- [x] 11. Create `werent/lib/controllers/booking_controller.dart` - API calls for bookings
- [x] 12. Update `db/mongodb.py` - Add vehicles and bookings collections
