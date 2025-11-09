from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    DashboardView,
    MoodUpdateView,
    ProfileView,
    RegisterView,
    WalletRechargeView,
)

urlpatterns = [
    path("auth/register/", RegisterView.as_view()),
    path("auth/token/", TokenObtainPairView.as_view()),
    path("auth/token/refresh/", TokenRefreshView.as_view()),
    path("profile/", ProfileView.as_view()),
    path("dashboard/", DashboardView.as_view()),
    path("mood/", MoodUpdateView.as_view()),
    path("wallet/recharge/", WalletRechargeView.as_view()),
]

