from django.urls import path
from . import views

# we_rent/urls.py
urlpatterns = [
    path('signup/', views.signup, name='signup'),
    path('login/', views.login_user, name='login'),
    path('vehicles/', views.vehicles, name='vehicles'),
    path('vehicles/<str:vehicle_id>/',
         views.vehicle_detail, name='vehicle_detail'),
    path('bookings/', views.bookings, name='bookings'),
    path('bookings/<str:booking_id>/',
         views.booking_detail, name='booking_detail'),
]
