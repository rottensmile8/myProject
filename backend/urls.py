from django.urls import path, include

urlpatterns = [
    path('api/', include('we_rent.urls')),  # Include we_rent app URLs
]
