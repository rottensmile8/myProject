
from .models import customer
from .serializers import customerSerializer
from rest_framework.generics import ListAPIView

# Create your views here.
class customerList(ListAPIView):
    queryset = customer.objects.all()
    serializer_class = customerSerializer
