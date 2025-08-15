# mukhostelapp

Makerere Hostel Finder - A modern mobile app built with Flutter and Supabase

## Features

✨ **Modern UI**: Material 3 design with Airbnb-inspired layouts  
🏠 **Hostel Discovery**: Browse hostels with advanced search and filtering  
📸 **Image Upload**: Full image upload and display for hostel photos  
⭐ **Reviews & Ratings**: Rate and review hostels  
❤️ **Favorites**: Save and manage favorite hostels  
🗺️ **Map Integration**: View hostel locations (coming soon)  
👥 **Role-based Access**: Student and Manager accounts  

## Tech Stack

- **Frontend**: Flutter with Material 3 UI
- **State Management**: Riverpod
- **Backend**: Supabase (Auth, Database, Storage)
- **Image Caching**: Cached Network Images

## Setup Instructions

### 1. Get the Project

**Option A: Clone with Git**
```bash
git clone <your-repo-url>
cd mukhostelapp
```

**Option B: Download ZIP**
1. Download the project as a ZIP file
2. Extract it to your desired location

### 2. Open in Your Preferred IDE

**Option A: Command Line**
```bash
cd mukhostelapp
flutter pub get
```

**Option B: Android Studio**
1. Open Android Studio
2. Click **"Open"** (or **"Open an Existing Project"**)
3. Navigate to and select the `mukhostelapp` folder
4. Click **"OK"** to open the project
5. Open the **Terminal** tab at the bottom of Android Studio
6. Run: `flutter pub get`
7. Select a device from the device dropdown (top toolbar)
8. Click the **"Run"** button (▶️) or press `Shift + F10`

### 3. Configure Supabase
1. Copy the template configuration file:
   ```bash
   cp lib/supabase_config.dart.template lib/supabase_config.dart
   ```
2. Update `lib/supabase_config.dart` with your actual Supabase credentials:
   - Replace `YOUR_SUPABASE_PROJECT_URL` with your Supabase project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your Supabase anonymous key
   
   Get these from your [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → Data API & API Keys

### 4. Run the App

**Command Line:**
```bash
flutter run
```

**Android Studio:**
- Ensure you've completed steps 1-3 above
- Device should already be selected from step 2
- Click the **"Run"** button (▶️) or press `Shift + F10`

> **Important**: Never commit your actual `supabase_config.dart` file with real API keys to version control. The file is already in `.gitignore` to prevent accidental commits.

## Prerequisites
- Flutter SDK (3.8.1+)
- Dart (3.8+)
- Supabase account

### 2. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Update `lib/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  static const String imagesBucket = 'hostel-images';
}
```

### 3. Database Schema

Create these tables in your Supabase SQL editor:

```sql
-- Profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hostels table
CREATE TABLE hostels (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  price INTEGER NOT NULL,
  amenities TEXT[] DEFAULT '{}',
  contact_info TEXT NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  is_available BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  rating FLOAT,
  review_count INTEGER DEFAULT 0
);

-- Reviews table
CREATE TABLE reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  hostel_id UUID REFERENCES hostels(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favorites table
CREATE TABLE favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  hostel_id UUID REFERENCES hostels(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, hostel_id)
);
```

### 4. Storage Setup

1. Create a storage bucket named `hostel-images`
2. Set it to public access for reading
3. Configure upload policies for authenticated users

### 5. Row Level Security (RLS) Policies

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hostels ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Hostels policies
CREATE POLICY "Hostels are viewable by everyone" ON hostels FOR SELECT USING (true);
CREATE POLICY "Managers can create hostels" ON hostels FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Managers can update own hostels" ON hostels FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Managers can delete own hostels" ON hostels FOR DELETE USING (auth.uid() = created_by);

-- Reviews policies
CREATE POLICY "Reviews are viewable by everyone" ON reviews FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON reviews FOR DELETE USING (auth.uid() = user_id);

-- Favorites policies
CREATE POLICY "Users can view own favorites" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (auth.uid() = user_id);
```

### 6. Storage Bucket Policies

For the `hostel-images` storage bucket, set these policies in Supabase Dashboard → Storage → hostel-images → Policies:

```sql
-- Allow public read access to images
CREATE POLICY "Public read access" ON storage.objects FOR SELECT USING (bucket_id = 'hostel-images');

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload" ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'hostel-images' AND auth.role() = 'authenticated');

-- Allow users to update their own images
CREATE POLICY "Users can update own images" ON storage.objects FOR UPDATE 
USING (bucket_id = 'hostel-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own images
CREATE POLICY "Users can delete own images" ON storage.objects FOR DELETE 
USING (bucket_id = 'hostel-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

> **Note**: The storage policies assume images are stored in folders named after the user's UUID (e.g., `hostels/user-uuid/image.jpg`).

### 7. Run the App

```bash
flutter pub get
flutter run
```

## User Roles

**Students**: 
- Sign in with email/password or Google OAuth
- Browse and search hostels
- Save favorites
- Write reviews

**Managers**:
- Sign up/in with email/password
- Create and manage hostel listings
- Upload hostel photos
- View analytics (coming soon)

## Development

The app uses a clean architecture with:
- `models/` - Data models
- `services/` - Supabase API calls
- `providers/` - Riverpod state management
- `screens/` - UI screens and widgets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of a university coursework assignment.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
