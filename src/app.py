import os
import traceback
from flask import Flask, render_template, request, jsonify
from google.cloud.sql.connector import Connector
import sqlalchemy

app = Flask(__name__)

# Database Configuration
INSTANCE_CONNECTION_NAME = os.environ.get("INSTANCE_CONNECTION_NAME")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASS = os.environ.get("DB_PASS", "")
DB_NAME = os.environ.get("DB_NAME", "postgres")

# Initialize DB Engine
engine = None
try:
    if INSTANCE_CONNECTION_NAME:
        connector = Connector()
        def getconn():
            return connector.connect(
                INSTANCE_CONNECTION_NAME,
                "pg8000",
                user=DB_USER,
                password=DB_PASS,
                db=DB_NAME,
                ip_type="PRIVATE" # Changed to PRIVATE because AlloyDB is in easy-alloydb-vpc
            )
        engine = sqlalchemy.create_engine("postgresql+pg8000://", creator=getconn, pool_pre_ping=True)
        print(f"Connected to AlloyDB: {INSTANCE_CONNECTION_NAME}")
    else:
        print("Warning: INSTANCE_CONNECTION_NAME not set. DB will not function.")
except Exception as e:
    print(f"Engine initialization error: {traceback.format_exc()}")

@app.route('/')
def home():
    """Renders the main CraveSaver UI."""
    return render_template('app.html')

@app.route('/api/query', methods=['POST'])
def query_db():
    """
    Takes natural language from the frontend, translates it via AlloyDB AI,
    executes it, and returns the food recommendations.
    """
    if not engine:
        return jsonify({"error": "Database not initialized"}), 500
        
    user_query = request.json.get("query", "").strip()
    if not user_query:
        return jsonify({"error": "Empty query"}), 400

    try:
        with engine.connect() as conn:
            # Step 1: Set Schema and Translate NL -> SQL using native AlloyDB AI Context
            conn.execute(sqlalchemy.text("SET search_path TO cravesaver, public;"))
            sql_gen_stmt = sqlalchemy.text("SELECT alloydb_ai_nl.get_sql(:query)")
            generated_sql = conn.execute(sql_gen_stmt, {"query": user_query}).scalar()

            if not generated_sql:
                return jsonify({"error": "Failed to translate query to SQL."}), 500

            print(f"[CraveSaver AI] Translated SQL: {generated_sql}")

            # Note: The query might contain the :human_prompt vector placeholder from our prescriptive rule.
            # We must replace it with the actual user query string for the vector lookup.
            final_sql = generated_sql.replace(":human_prompt", f"'{user_query}'")
            final_sql = final_sql.replace(";", " LIMIT 5;") # Ensure we don't return 100 rows

            # Step 2: Execute the AI-generated SQL
            execution_stmt = sqlalchemy.text(final_sql)
            result = conn.execute(execution_stmt)
            
            dishes = []
            for row in result.mappings():
                # Don't serialize the raw binary vector to the frontend
                dish = dict(row)
                if 'mood_embedding' in dish:
                    del dish['mood_embedding'] 
                dishes.append(dish)

            return jsonify({
                "generated_sql": final_sql,
                "results": dishes
            })
            
    except Exception as e:
        print(f"Query Error: {traceback.format_exc()}")
        return jsonify({
            "error": "Query execution failed.",
            "details": str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, threaded=True)
