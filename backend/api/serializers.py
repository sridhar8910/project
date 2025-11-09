from django.contrib.auth.models import User
from rest_framework import serializers

from .models import UserProfile


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    age = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    gender = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ("username", "email", "password", "full_name", "phone", "age", "gender")

    def validate_username(self, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise serializers.ValidationError("Username cannot be blank")
        if not normalized.isalnum():
            raise serializers.ValidationError("Username must be letters and numbers only")
        normalized = normalized.lower()
        if User.objects.filter(username=normalized).exists():
            raise serializers.ValidationError("Username already exists")
        return normalized

    def validate_email(self, value: str) -> str:
        if value and User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already in use")
        return value

    def create(self, validated_data):
        profile_fields = {
            "full_name": validated_data.pop("full_name", ""),
            "phone": validated_data.pop("phone", ""),
            "age": validated_data.pop("age", None),
            "gender": validated_data.pop("gender", ""),
        }
        normalized_email = validated_data.get("email")
        if normalized_email:
            normalized_email = normalized_email.strip().lower()

        user = User.objects.create_user(
            username=validated_data["username"],
            email=normalized_email,
            password=validated_data["password"],
        )
        profile, _ = UserProfile.objects.get_or_create(user=user)
        for attr, value in profile_fields.items():
            if value not in (None, "", []):
                setattr(profile, attr, value)
        profile.save()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.CharField(source="user.email", read_only=True)

    class Meta:
        model = UserProfile
        fields = (
            "username",
            "email",
            "full_name",
            "phone",
            "age",
            "gender",
            "wallet_minutes",
            "last_mood",
            "last_mood_updated",
            "created_at",
        )
        read_only_fields = ("wallet_minutes", "last_mood", "last_mood_updated")


class MoodUpdateSerializer(serializers.Serializer):
    value = serializers.IntegerField(min_value=1, max_value=5)


class WalletRechargeSerializer(serializers.Serializer):
    minutes = serializers.IntegerField(min_value=1, max_value=600)

