from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    
    path('admin/', admin.site.urls),
    
    path('api/', include('we_rent.urls')),  # Include we_rent app URLs
]
