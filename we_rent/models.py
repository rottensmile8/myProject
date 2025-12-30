from django.db import models

# Create your models here.
class customer(models.Model):
    customerName = models.CharField(max_length = 100)
    email = models.CharField(max_length = 100)