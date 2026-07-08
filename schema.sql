-- Rentzy DB Schema

-- Create USERS table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT NOT NULL, -- Will store hashed password
    phone VARCHAR(50),
    photo TEXT,
    lat DECIMAL(9,6),
    long DECIMAL(9,6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create PROPERTIES table
CREATE TABLE IF NOT EXISTS properties (
    property_id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL,
    property_type VARCHAR(50) NOT NULL, -- 'rent' or 'sale'
    furnishing VARCHAR(50),             -- 'fully', 'semi', 'unfurnished'
    amenities TEXT,                     -- Comma-separated list of amenities: AC, WiFi, Parking, etc.
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    lat DECIMAL(9,6) NOT NULL,
    long DECIMAL(9,6) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create PROPERTY_IMAGES table
CREATE TABLE IF NOT EXISTS property_images (
    image_id SERIAL PRIMARY KEY,
    property_id INT REFERENCES properties(property_id) ON DELETE CASCADE,
    image_url TEXT NOT NULL
);

-- Create RATINGS table
CREATE TABLE IF NOT EXISTS ratings (
    rating_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    property_id INT REFERENCES properties(property_id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for geographic searches
CREATE INDEX IF NOT EXISTS idx_properties_lat_long ON properties(lat, long);

-- Insert Seed Data
-- Seed Users (passwords are SHA-256 hash of 'password123': 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f')
INSERT INTO users (name, email, password, phone, photo, lat, long) VALUES
('John Doe', 'john@example.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', '+1-555-0199', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 37.774929, -122.419416),
('Jane Smith', 'jane@example.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', '+1-555-0200', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', 37.783333, -122.416667)
ON CONFLICT (email) DO NOTHING;

-- Seed Properties (John owns property 1, Jane owns property 2)
-- Coordinates are in San Francisco area. John is at (37.774929, -122.419416)
-- Property 1 (Soma) is at (37.777000, -122.415000) ~0.44 km from John.
-- Property 2 (Sunset) is at (37.750000, -122.480000) ~6.0 km from John.
-- Property 3 (Mission) is at (37.760000, -122.420000) ~1.6 km from John.
INSERT INTO properties (owner_id, title, description, price, property_type, furnishing, amenities, address, city, lat, long, is_available) VALUES
(1, 'Modern SoMa Loft', 'Beautiful open space loft in the heart of SoMa. Includes concrete floors, high ceilings, large windows, and a private balcony.', 3200.00, 'rent', 'fully', 'AC,WiFi,Gym,Parking', '450 Folsom St, San Francisco, CA', 'San Francisco', 37.777000, -122.415000, true),
(2, 'Sunset Cozy House', 'Charming 2-bedroom house in the quiet Sunset district. Large backyard, close to Golden Gate Park and the beach.', 4500.00, 'rent', 'unfurnished', 'WiFi,Parking', '1240 Judah St, San Francisco, CA', 'San Francisco', 37.750000, -122.480000, true),
(1, 'Luxury Mission Penthouse', 'High-end 3-bedroom penthouse with panoramic views of the city. Modern kitchen and rooftop deck.', 850000.00, 'sale', 'semi', 'AC,WiFi,Gym,Pool,Parking', '900 Valencia St, San Francisco, CA', 'San Francisco', 37.760000, -122.420000, true)
ON CONFLICT DO NOTHING;

-- Seed Property Images
INSERT INTO property_images (property_id, image_url) VALUES
(1, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800'),
(1, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'),
(2, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800'),
(3, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800')
ON CONFLICT DO NOTHING;

-- Seed Ratings
INSERT INTO ratings (user_id, property_id, rating, review) VALUES
(2, 1, 5, 'Absolutely spectacular! Highly recommend to anyone looking for a clean and central place.'),
(1, 2, 4, 'Very cozy, nice garden. Just a bit far from the downtown, but excellent transit options.')
ON CONFLICT DO NOTHING;
