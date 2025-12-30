from django.contrib import admin
from .models import customer

# Register your models here.
@admin.register(customer)
class customerAdmin(admin.ModelAdmin):
    list_display = ['id', 'customerName', 'email']
    
    
    