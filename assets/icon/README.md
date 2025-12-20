# App Icon Instructions

## How to Add Your Launcher Icon

1. **Create or prepare your icon image:**
   - Size: 1024x1024 pixels (recommended)
   - Format: PNG with transparency support
   - Design: Square image with your app logo/icon
   - Background: Can be transparent or solid color

2. **Save your icon:**
   - Name the file: `app_icon.png`
   - Place it in this directory: `assets/icon/app_icon.png`

3. **Generate the launcher icons:**
   After placing your icon file, run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **For Android Adaptive Icons:**
   - The adaptive icon background color is set to `#F96A46` (your app's primary color)
   - If you want to change it, edit the `adaptive_icon_background` value in `pubspec.yaml`

## Icon Design Tips

- Keep important content in the center 80% of the image (safe zone)
- Use high contrast colors for better visibility
- Avoid text unless it's part of your logo
- Test on both light and dark backgrounds

## Current Configuration

- **Android**: Enabled with adaptive icon support
- **iOS**: Enabled
- **Background Color**: #F96A46 (Warm Orange-Red)
- **Minimum Android SDK**: 21

