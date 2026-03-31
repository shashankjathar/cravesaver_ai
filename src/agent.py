import os
from google.cloud.sql.connector import Connector
import sqlalchemy

# ==============================================================
# Agent Logic for Natural Language queries against AlloyDB
# ==============================================================

# Database Connection variables from environment
INSTANCE_CONNECTION_NAME = os.environ.get("INSTANCE_CONNECTION_NAME", "") 
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASS = os.environ.get("DB_PASS", "")
DB_NAME = os.environ.get("DB_NAME", "postgres")

def process_nl_query(nl_question: str) -> str:
    """
    Connects to AlloyDB, translates the natural language query into SQL
    using alloydb_ai_nl, executes the generated SQL and returns the results.
    """
    if not INSTANCE_CONNECTION_NAME:
        return "Error: Database connection details missing in environment variables."

    connector = Connector()
    def getconn():
        return connector.connect(
            INSTANCE_CONNECTION_NAME,
            "pg8000",
            user=DB_USER,
            password=DB_PASS,
            db=DB_NAME,
            ip_type="PRIVATE" # Set to PUBLIC if not using VPC peering
        )
    
    pool = sqlalchemy.create_engine(
        "postgresql+pg8000://",
        creator=getconn,
    )
    
    try:
        with pool.connect() as db_conn:
            # 1. Provide the Natural Language query to the AI extension
            # get_sql() attempts to understand the database schema and writes a PostgreSQL query
            query_statement = sqlalchemy.text("SELECT alloydb_ai_nl.get_sql(:question)")
            generated_sql = db_conn.execute(query_statement, parameters={"question": nl_question}).scalar()
            
            if not generated_sql:
                return "The AI system could not generate a SQL query for your input."
                
            print(f"[Agent Debug] Generated SQL executed: {generated_sql}")
            
            # 2. Execute the AI generated SQL
            # IMPORTANT: In a production environment, ensure you use read-only users or Parameterized Secure Views 
            # to prevent malicious prompt injection.
            data_statement = sqlalchemy.text(generated_sql)
            results = db_conn.execute(data_statement).mappings().all()
            
            # 3. Format the result back to the user
            output = [f"Generated SQL: {generated_sql}", f"Found {len(results)} records."]
            for row in results:
                output.append(str(dict(row)))
                
            return "\n".join(output)
            
    except Exception as e:
        return f"Database execution error: {str(e)}"
    finally:
        connector.close()


# ==============================================================
# Google Cloud ADK (Agent Development Kit) Integration
# ==============================================================
# Depending on your exact version of the Google Cloud ADK (e.g. adk, google-genai, vertexai-agent-engine)
# The syntax generally follows wrapping python functions into agent tools:

try:
    from adk import agent, tool 
    
    @agent(
        name="LibraryDatabaseAgent",
        description="I am an assistant the querying the local library book catalog database."
    )
    class LibraryAgent:
        
        @tool(description="Convert english questions about books and authors into database queries, execute them, and return results.")
        def query_database(self, user_question: str) -> str:
            return process_nl_query(user_question)
            
except ImportError:
    print("Warning: 'adk' library not found. Running in standalone fallback mode.")
    # Fallback basic CLI test if ADK is missing:
    if __name__ == "__main__":
        print("--- Library Catalog Agent Test ---")
        prompt = input("Enter your natural language question: ")
        print(process_nl_query(prompt))
