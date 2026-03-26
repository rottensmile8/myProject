from django.contrib import admin
from .models import User

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    # Columns to show in the list view
    list_display = ('fullName', 'email', 'isActive', 'role')
    # Filters on the right side
    list_filter = ('isActive', 'role')
    # Search box for finding specific users
    search_fields = ('fullName', 'email')
    # Allow quick editing of isActive status in the list
    list_editable = ('isActive',)
