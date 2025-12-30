from django.urls import path
from we_rent import views


urlpatterns = [
    path('customer/', views.customerList.as_view()),
]