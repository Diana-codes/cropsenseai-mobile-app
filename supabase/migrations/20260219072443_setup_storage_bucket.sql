/*
  # Storage Bucket Setup for Disease Images

  ## Overview
  Creates storage bucket and RLS policies for disease detection images uploaded by users.

  ## Changes
  1. Creates `disease-images` public storage bucket
  2. Sets up RLS policies for:
     - User uploads (authenticated users only)
     - User viewing (own images)
     - Public viewing (for sharing)
     - User deletion (own images)

  ## Storage Structure
  Images are stored as: `detections/{user_id}/{timestamp}.jpg`
*/

-- Create storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('disease-images', 'disease-images', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Users can upload their own images
CREATE POLICY "Users can upload own disease images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'disease-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can view their own images
CREATE POLICY "Users can view own disease images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'disease-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Public can view images (for sharing)
CREATE POLICY "Public can view disease images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'disease-images');

-- Policy: Users can delete their own images
CREATE POLICY "Users can delete own disease images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'disease-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
