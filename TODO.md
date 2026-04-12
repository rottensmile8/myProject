# TODO: Implement One Active Rental Per Renter

## Steps (Approved Plan):

- [x] **Step 1**: Edit we_rent/views.py - Add backend validation in POST /bookings/ to reject if renter has existing 'confirmed' booking.
- [x] **Step 2**: Edit werent/lib/controllers/booking_controller.dart - Add hasActiveRental(String renterId) method.
- [x] **Step 3**: Edit werent/lib/auth/browse_vehicles.dart - Check hasActiveRental before showing booking dialog, promote saved vehicles.
- [x] **Step 4**: Edit werent/lib/auth/renter_dashboard.dart - Show active rental status, disable/block Browse if active rental exists.
- [x] **Step 5**: Test full flow (backend rejection, frontend blocks, saved vehicles work).
- [x] **Done**: All steps complete!

**Progress**: 6/6 complete ✅
