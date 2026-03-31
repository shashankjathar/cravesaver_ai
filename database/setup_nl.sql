-- database/setup_nl.sql
-- Run this in psql after running schema.sql

-- 1. Enable the AI Extension
CREATE EXTENSION IF NOT EXISTS alloydb_ai_nl CASCADE;

-- 2. Grant permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA alloydb_ai_nl TO current_user;

-- 3. Define Context Metadata to train the AI translation model
-- This teaches the 'get_sql' function that it can do hard filters (math/ops) on price & mins
-- and do subjective vector matches on 'flavor_profile' through 'mood_embedding'
COMMENT ON TABLE cravesaver.dishes IS 'A restaurant food delivery menu. Use this to find dishes matching user constraints on price, dietary_type, delivery_time, and descriptive subjective moods. Wait time is the est_delivery_mins column. Diet is dietary_type. CRITICAL INSTRUCTION: For queries mentioning subjective feelings, vibes, descriptions or moods (e.g., "I feel sad", "comfort food", "healthy post-workout"), always sort using an inner vector distance match against mood_embedding: ORDER BY mood_embedding <=> embedding(''textembedding-gecko'', :human_prompt)::vector ASC.';

COMMENT ON COLUMN cravesaver.dishes.price IS 'The cost of the dish in INR or rupees. Used for budget or cheap food filters.';
COMMENT ON COLUMN cravesaver.dishes.est_delivery_mins IS 'The maximum estimated time it takes for this food to be prepared and delivered, measured in minutes. Used for speed, fast, or wait-time filters.';
COMMENT ON COLUMN cravesaver.dishes.mood_embedding IS 'A pre-computed 768-dimensional vector representing the dish flavor_profile. Used for subjective emotional or semantic matching. The similarity operator is <=>';

-- 4. Teach the model exactly how to combine math and AI
-- We inserted the prescriptive rule directly into the TABLE COMMENT above (which acts as system instructions).

-- Example Translation Queries to try later:
-- "Find me a vegan meal under $15 that I can eat in 25 minutes"
-- "I am feeling gloomy and need carbs under 20 bucks delivered in less than an hour."
