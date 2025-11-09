from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import UserProfile
from .serializers import (
    MoodUpdateSerializer,
    RegisterSerializer,
    UserProfileSerializer,
    WalletRechargeSerializer,
)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        profile, _created = UserProfile.objects.get_or_create(user=self.request.user)
        return profile


class DashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile_data = UserProfileSerializer(profile).data

        data = {
            "profile": profile_data | {"display_name": request.user.username.title()},
            "wallet": {"minutes": profile.wallet_minutes},
            "mood": {
                "value": profile.last_mood,
                "updated_at": profile.last_mood_updated,
            },
            "upcoming": {
                "title": "Upcoming",
                "description": "No sessions scheduled",
            },
            "quick_actions": [
                {"title": "Schedule Session", "icon": "calendar_today"},
                {"title": "Mental Health", "icon": "psychology"},
                {"title": "Expert Connect", "icon": "person_outline"},
                {"title": "Meditation", "icon": "self_improvement"},
            ],
        }
        return Response(data)


class MoodUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = MoodUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile.last_mood = serializer.validated_data["value"]
        profile.last_mood_updated = timezone.now()
        profile.save(update_fields=["last_mood", "last_mood_updated"])
        return Response(
            {
                "status": "ok",
                "mood": profile.last_mood,
                "updated_at": profile.last_mood_updated,
            }
        )


class WalletRechargeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = WalletRechargeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        minutes = serializer.validated_data["minutes"]
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        profile.wallet_minutes += minutes
        profile.save(update_fields=["wallet_minutes"])
        return Response(
            {"status": "ok", "wallet_minutes": profile.wallet_minutes},
            status=status.HTTP_200_OK,
        )

