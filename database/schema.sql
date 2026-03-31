-- database/schema.sql
-- Run this in psql after connecting to your database

-- 1. Enable required vector and ml extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS google_ml_integration CASCADE;

-- 2. Create the custom schema
CREATE SCHEMA IF NOT EXISTS cravesaver;

-- 3. Create the core menu table
CREATE TABLE IF NOT EXISTS cravesaver.dishes (
    dish_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(255) NOT NULL,
    dish_name VARCHAR(255) NOT NULL,
    price NUMERIC(8,2) NOT NULL,
    est_delivery_mins INT NOT NULL,
    dietary_type VARCHAR(50), -- e.g., 'Vegetarian', 'Vegan', 'Omnivore'
    description TEXT NOT NULL,
    flavor_profile TEXT NOT NULL, -- The psychological/vibe description for the AI to read
    mood_embedding vector(768) -- Vector for semantic search based on 'textembedding-gecko@003' embeddings
);

-- Clear existing data if re-running
TRUNCATE TABLE cravesaver.dishes RESTART IDENTITY CASCADE;

-- 4. Seed the Dataset and Auto-generate Vector Embeddings on Insert
-- Notice the use of 'embedding(..., text)::vector' - this proves the "AI Database" capability
-- directly in SQL without needing a Python middleman.

INSERT INTO cravesaver.dishes (restaurant_name, dish_name, price, est_delivery_mins, dietary_type, description, flavor_profile, mood_embedding)
VALUES 
('Noodle Hug', 'Spicy Miso Ramen', 450.00, 45, 'Omnivore', 'Rich pork broth with thick noodles, soft boiled egg, and chili oil.', 'Comforting, warm, intensely flavorful, perfect for a cold rainy gloomy day.', embedding('textembedding-gecko', 'Comforting, warm, intensely flavorful, perfect for a cold rainy gloomy day.')::vector),
('Mama Pizza', 'Double Cheese Deep Dish', 800.00, 55, 'Vegetarian', 'Massive heavy thick crust loaded with six cheeses and chunky tomato sauce.', 'Heavy, indulgent, carb-coma, feeling down and needing pure junk food comfort.', embedding('textembedding-gecko', 'Heavy, indulgent, carb-coma, feeling down and needing pure junk food comfort.')::vector),
('Green Energy', 'Quinoa Berry Power Bowl', 350.00, 20, 'Vegan', 'Fresh mixed berries, tri-color quinoa, almond slivers, and a light lemon vinaigrette.', 'Light, refreshing, energizing, clean eating, feeling healthy and active post-workout.', embedding('textembedding-gecko', 'Light, refreshing, energizing, clean eating, feeling healthy and active post-workout.')::vector),
('Taco Blitz', 'Five Alarm Burrito', 250.00, 15, 'Omnivore', 'Huge burrito packed with steak, ghost pepper salsa, rice, and beans.', 'Spicy, sweat-inducing, exciting, fast food for a hungry thrill seeker on a budget.', embedding('textembedding-gecko', 'Spicy, sweat-inducing, exciting, fast food for a hungry thrill seeker on a budget.')::vector),
('Midnight Bakery', 'Warm Chocolate Lava Cake', 200.00, 25, 'Vegetarian', 'A single serving of rich dark chocolate cake with a molten center.', 'Sweet, romantic, late-night craving, comforting treat.', embedding('textembedding-gecko', 'Sweet, romantic, late-night craving, comforting treat.')::vector),
('Soup Sanctum', 'Chicken Noodle Soup', 280.00, 30, 'Omnivore', 'Classic clear broth with carrots, celery, and homestyle noodles.', 'Sick day remedy, soothing, warm, nostalgic and familiar.', embedding('textembedding-gecko', 'Sick day remedy, soothing, warm, nostalgic and familiar.')::vector),
('Salad Expressway', 'Grilled Chicken Caesar', 320.00, 15, 'Omnivore', 'Crisp romaine, heavy cream dressing, crunchy croutons, and grilled breast.', 'Crisp, standard, fast, reliable work lunch.', embedding('textembedding-gecko', 'Crisp, standard, fast, reliable work lunch.')::vector),
('Zen Bento', 'Vegan Sushi Platter', 650.00, 35, 'Vegan', 'Delicate rolls filled with avocado, sweet potato tempura, and pickled radish.', 'Elegant, clean, mindful eating, visually pleasing and light.', embedding('textembedding-gecko', 'Elegant, clean, mindful eating, visually pleasing and light.')::vector),
('Bros Burgers', 'Triple Smash Patty', 500.00, 25, 'Omnivore', 'Three smashed beef patties with bacon, grease, and American cheese.', 'Greasy, hangover cure, heavily savory and unpretentious.', embedding('textembedding-gecko', 'Greasy, hangover cure, heavily savory and unpretentious.')::vector),
('Thai Basil Express', 'Pad Kee Mao (Drunken Noodles)', 420.00, 30, 'Omnivore', 'Wide rice noodles in dark soy sauce sauce with intense basil and chilis.', 'Savory, spicy, late-night street food vibe, intensely aromatic.', embedding('textembedding-gecko', 'Savory, spicy, late-night street food vibe, intensely aromatic.')::vector);

-- Verification
SELECT 'Dishes Seeded successfully:' AS status, COUNT(*) FROM cravesaver.dishes;
