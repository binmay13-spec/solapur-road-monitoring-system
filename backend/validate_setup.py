# NEW FILE | Utility
# Project Setup Validation Script
# Cross-checks Firebase Admin SDK and Supabase connectivity

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def check_firebase():
    print("--- Checking Firebase Configuration ---")
    service_account_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "firebase_service.json")
    
    if not os.path.exists(service_account_path):
        print("[FAIL] firebase_service.json not found in backend/ folder.")
        return False
        
    try:
        from config.firebase_config_new import get_firebase_app
        app = get_firebase_app()
        print(f"[OK] Firebase Admin SDK initialized for project: {app.project_id}")
        return True
    except Exception as e:
        print(f"[FAIL] Firebase initialization failed: {e}")
        return False

def check_supabase():
    print("\n--- Checking Supabase Connectivity ---")
    try:
        from config.supabase_config_new import test_connection
        if test_connection():
            print("[OK] Supabase connected successfully.")
            return True
        else:
            print("[FAIL] Supabase connection test failed.")
            return False
    except Exception as e:
        print(f"[FAIL] Supabase test failed: {e}")
        return False

def check_schema():
    print("\n--- Verifying Database Schema ---")
    try:
        from config.supabase_config_new import get_supabase_client
        client = get_supabase_client()
        
        # Check for core tables
        tables = ["users", "reports", "workers", "attendance"]
        missing = []
        
        for table in tables:
            try:
                client.table(table).select("count", count="exact").limit(1).execute()
                print(f"[OK] Table '{table}' verified.")
            except Exception:
                print(f"[FAIL] Table '{table}' seems missing or inaccessible.")
                missing.append(table)
                
        if not missing:
            print("[OK] Core database schema appears to be in place.")
            return True
        else:
            print(f"[WARNING] Some tables are missing. Did you run schema.sql?")
            return False
    except Exception as e:
        print(f"[FAIL] Schema verification error: {e}")
        return False

if __name__ == "__main__":
    print("========================================")
    print(" Smart Road Monitor: SYSTEM VALIDATOR   ")
    print("========================================\n")
    
    fb_ok = check_firebase()
    sb_ok = check_supabase()
    schema_ok = check_schema()
    
    print("\n========================================")
    if fb_ok and sb_ok and schema_ok:
        print(" SUCCESS: System is properly configured! ")
    else:
        print(" ERROR: Some components failed cross-check. ")
    print("========================================")
