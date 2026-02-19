/*
  # CropSense AI Disease Detection Schema

  ## Overview
  This migration creates the complete database schema for the CropSense AI disease 
  detection system, integrating with the trained MobileNetV2 model.

  ## New Tables
  
  ### 1. `crop_diseases`
  Stores disease information and metadata
  - `id` (uuid, primary key)
  - `name` (text) - Disease name (Healthy, Powdery, Rust)
  - `scientific_name` (text) - Scientific classification
  - `description` (text) - Disease description
  - `symptoms` (text[]) - Array of symptoms
  - `severity_level` (text) - low, medium, high, critical
  - `affected_crops` (text[]) - Crops affected by this disease
  - `image_url` (text) - Reference image URL
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 2. `disease_detections`
  Stores user disease scan history and predictions
  - `id` (uuid, primary key)
  - `user_id` (uuid, foreign key to auth.users)
  - `disease_id` (uuid, foreign key to crop_diseases)
  - `image_url` (text) - Uploaded image URL
  - `confidence_score` (float) - Model confidence (0-1)
  - `top_predictions` (jsonb) - Top 3 predictions with scores
  - `location` (text) - User location
  - `crop_type` (text) - Type of crop scanned
  - `notes` (text) - User notes
  - `status` (text) - pending, confirmed, treated
  - `created_at` (timestamptz)

  ### 3. `crop_calendar`
  Rwanda crop calendar data for season-aware recommendations
  - `id` (uuid, primary key)
  - `crop` (text) - Crop name
  - `season` (text) - Season A or B
  - `district` (text) - Rwanda district
  - `planting_month` (int) - Month to plant
  - `harvest_month` (int) - Month to harvest
  - `variety` (text) - Crop variety
  - `seed_type` (text) - Seed type
  - `optimal_conditions` (jsonb) - Weather conditions
  - `created_at` (timestamptz)

  ### 4. `recommendations`
  Treatment and management recommendations
  - `id` (uuid, primary key)
  - `disease_id` (uuid, foreign key to crop_diseases)
  - `recommendation_type` (text) - treatment, prevention, management
  - `title` (text)
  - `description` (text)
  - `steps` (text[]) - Array of action steps
  - `products` (jsonb) - Recommended products
  - `organic_options` (text[]) - Organic alternatives
  - `cost_estimate` (numeric) - Estimated cost in RWF
  - `effectiveness_rating` (int) - 1-5 rating
  - `priority` (int) - Display priority
  - `created_at` (timestamptz)

  ### 5. `user_farms`
  User farm information
  - `id` (uuid, primary key)
  - `user_id` (uuid, foreign key to auth.users)
  - `farm_name` (text)
  - `location` (text)
  - `district` (text)
  - `size_hectares` (numeric)
  - `crops` (text[]) - Crops grown
  - `created_at` (timestamptz)

  ## Security
  - Enable RLS on all tables
  - Users can only access their own data
  - Public read access to disease info, calendar, and recommendations
*/

-- ============================================================================
-- TABLE: crop_diseases
-- ============================================================================

CREATE TABLE IF NOT EXISTS crop_diseases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  scientific_name text,
  description text NOT NULL,
  symptoms text[] DEFAULT '{}',
  severity_level text NOT NULL CHECK (severity_level IN ('low', 'medium', 'high', 'critical')),
  affected_crops text[] DEFAULT '{}',
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE crop_diseases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read disease info"
  ON crop_diseases
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- TABLE: disease_detections
-- ============================================================================

CREATE TABLE IF NOT EXISTS disease_detections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  disease_id uuid REFERENCES crop_diseases(id) ON DELETE SET NULL,
  image_url text NOT NULL,
  confidence_score float NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
  top_predictions jsonb DEFAULT '[]'::jsonb,
  location text,
  crop_type text,
  notes text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'treated', 'resolved')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE disease_detections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own detections"
  ON disease_detections
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own detections"
  ON disease_detections
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own detections"
  ON disease_detections
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own detections"
  ON disease_detections
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE: crop_calendar
-- ============================================================================

CREATE TABLE IF NOT EXISTS crop_calendar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crop text NOT NULL,
  season text NOT NULL CHECK (season IN ('Season A', 'Season B', 'Year Round')),
  district text,
  planting_month int CHECK (planting_month >= 1 AND planting_month <= 12),
  harvest_month int CHECK (harvest_month >= 1 AND harvest_month <= 12),
  variety text,
  seed_type text,
  optimal_conditions jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE crop_calendar ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read crop calendar"
  ON crop_calendar
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- TABLE: recommendations
-- ============================================================================

CREATE TABLE IF NOT EXISTS recommendations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disease_id uuid REFERENCES crop_diseases(id) ON DELETE CASCADE,
  recommendation_type text NOT NULL CHECK (recommendation_type IN ('treatment', 'prevention', 'management')),
  title text NOT NULL,
  description text NOT NULL,
  steps text[] DEFAULT '{}',
  products jsonb DEFAULT '[]'::jsonb,
  organic_options text[] DEFAULT '{}',
  cost_estimate numeric DEFAULT 0,
  effectiveness_rating int CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),
  priority int DEFAULT 1,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read recommendations"
  ON recommendations
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- TABLE: user_farms
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_farms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  farm_name text NOT NULL,
  location text,
  district text,
  size_hectares numeric,
  crops text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_farms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own farms"
  ON user_farms
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own farms"
  ON user_farms
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own farms"
  ON user_farms
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_detections_user_id ON disease_detections(user_id);
CREATE INDEX IF NOT EXISTS idx_detections_disease_id ON disease_detections(disease_id);
CREATE INDEX IF NOT EXISTS idx_detections_created_at ON disease_detections(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_disease_id ON recommendations(disease_id);
CREATE INDEX IF NOT EXISTS idx_crop_calendar_crop ON crop_calendar(crop);
CREATE INDEX IF NOT EXISTS idx_crop_calendar_district ON crop_calendar(district);
CREATE INDEX IF NOT EXISTS idx_user_farms_user_id ON user_farms(user_id);

-- ============================================================================
-- SEED DATA: Disease Information
-- ============================================================================

INSERT INTO crop_diseases (name, scientific_name, description, symptoms, severity_level, affected_crops)
VALUES
  (
    'Healthy',
    'N/A',
    'No disease detected. Plant shows normal, healthy characteristics.',
    ARRAY['Green vibrant leaves', 'Normal growth pattern', 'No discoloration', 'No lesions or spots'],
    'low',
    ARRAY['All crops']
  ),
  (
    'Powdery Mildew',
    'Erysiphales',
    'Fungal disease characterized by white powdery spots on leaves and stems. Thrives in warm, dry climates with high humidity.',
    ARRAY['White powdery coating on leaves', 'Yellowing leaves', 'Stunted growth', 'Leaf curling', 'Reduced yield'],
    'medium',
    ARRAY['Beans', 'Tomatoes', 'Cucumbers', 'Squash', 'Grapes']
  ),
  (
    'Rust',
    'Pucciniales',
    'Fungal disease causing rust-colored pustules on leaves. Spreads rapidly in humid conditions.',
    ARRAY['Orange-brown pustules', 'Yellowing leaves', 'Premature leaf drop', 'Weakened plants', 'Reduced photosynthesis'],
    'high',
    ARRAY['Beans', 'Coffee', 'Wheat', 'Corn', 'Soybeans']
  )
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- SEED DATA: Treatment Recommendations
-- ============================================================================

INSERT INTO recommendations (disease_id, recommendation_type, title, description, steps, products, organic_options, cost_estimate, effectiveness_rating, priority)
SELECT 
  d.id,
  'treatment',
  'Fungicide Application for Powdery Mildew',
  'Apply approved fungicides to control powdery mildew infection and prevent spread.',
  ARRAY[
    'Remove heavily infected leaves',
    'Apply fungicide early morning or evening',
    'Ensure thorough coverage of all plant surfaces',
    'Repeat application every 7-14 days',
    'Monitor plant response'
  ],
  '[{"name": "Sulfur-based fungicide", "dosage": "2-3g per liter"}, {"name": "Neem oil", "dosage": "5ml per liter"}]'::jsonb,
  ARRAY['Baking soda solution (1 tbsp per liter)', 'Milk spray (1:9 ratio)', 'Neem oil'],
  5000,
  4,
  1
FROM crop_diseases d WHERE d.name = 'Powdery Mildew'
ON CONFLICT DO NOTHING;

INSERT INTO recommendations (disease_id, recommendation_type, title, description, steps, products, organic_options, cost_estimate, effectiveness_rating, priority)
SELECT 
  d.id,
  'prevention',
  'Cultural Practices for Powdery Mildew Prevention',
  'Implement good agricultural practices to prevent powdery mildew occurrence.',
  ARRAY[
    'Ensure proper plant spacing for air circulation',
    'Avoid overhead watering',
    'Water in the morning to allow drying',
    'Remove plant debris regularly',
    'Use resistant varieties when available'
  ],
  '[]'::jsonb,
  ARRAY['Compost tea spray', 'Garlic extract'],
  1000,
  5,
  2
FROM crop_diseases d WHERE d.name = 'Powdery Mildew'
ON CONFLICT DO NOTHING;

INSERT INTO recommendations (disease_id, recommendation_type, title, description, steps, products, organic_options, cost_estimate, effectiveness_rating, priority)
SELECT 
  d.id,
  'treatment',
  'Rust Disease Management',
  'Control rust infection using approved fungicides and cultural practices.',
  ARRAY[
    'Remove and destroy infected plant parts',
    'Apply appropriate fungicide',
    'Improve air circulation',
    'Avoid working with wet plants',
    'Apply protective fungicide to healthy plants'
  ],
  '[{"name": "Copper-based fungicide", "dosage": "As per label"}, {"name": "Mancozeb", "dosage": "As per label"}]'::jsonb,
  ARRAY['Bordeaux mixture', 'Copper soap', 'Sulfur dust'],
  7000,
  4,
  1
FROM crop_diseases d WHERE d.name = 'Rust'
ON CONFLICT DO NOTHING;

INSERT INTO recommendations (disease_id, recommendation_type, title, description, steps, products, organic_options, cost_estimate, effectiveness_rating, priority)
SELECT 
  d.id,
  'prevention',
  'Rust Prevention Strategy',
  'Preventive measures to reduce rust disease incidence.',
  ARRAY[
    'Plant rust-resistant varieties',
    'Rotate crops annually',
    'Maintain proper plant nutrition',
    'Avoid excessive nitrogen fertilization',
    'Remove volunteer plants and weeds'
  ],
  '[]'::jsonb,
  ARRAY['Compost', 'Crop rotation'],
  2000,
  5,
  2
FROM crop_diseases d WHERE d.name = 'Rust'
ON CONFLICT DO NOTHING;