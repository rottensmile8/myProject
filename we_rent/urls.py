from django.urls import path
from . import views

# we_rent/urls.py
urlpatterns = [
    path('signup/', views.signup, name='signup'),
    path('login/', views.login_user, name='login'),  # Fixed: was 'views.login'
]
