#!/bin/bash

echo "🚀 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
  echo "❌ Error: Flutter is not installed. Please install Flutter first."
  exit 1
fi

echo "🔍 Getting Flutter dependencies..."
flutter pub get

echo "🔄 Running Flutter doctor to check setup..."
flutter doctor

echo "✅ Setup complete! You can now run your Flutter project. 🎉"
@echo off
echo 🚀 Checking Flutter installation...
where flutter >nul 2>nul
IF ERRORLEVEL 1 (
    echo ❌ Error: Flutter is not installed. Please install Flutter first.
    exit /b 1
)

echo 🔍 Getting Flutter dependencies...
flutter pub get

echo 🔄 Running Flutter doctor to check setup...
flutter doctor

echo ✅ Setup complete! You can now run your Flutter project. 🎉

