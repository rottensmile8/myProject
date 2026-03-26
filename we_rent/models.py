from django.db import models

# Create your models here.
class User(models.Model):
    fullName = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=[('renter', 'Renter'), ('owner', 'Owner')])
    isActive = models.BooleanField(default=False)
    
    def __str__(self):
        return self.fullName