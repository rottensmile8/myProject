# Fix Return Button in Rental History

## Steps:

1. [ ] Add VehicleController import and instance to rental_history_screen.dart
2. [ ] Update \_updateStatus to call \_vehicleController.toggleAvailability(booking.vehicleId) after booking status update when status=='completed'
3. [ ] Add success/error handling and refresh
4. [ ] Test end-to-end: confirmed rental -> return -> vehicle available
5. [ ] Complete task
