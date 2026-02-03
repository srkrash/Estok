import json
import os
import urllib.parse
import sys
import secrets

# Default Configuration
DEFAULT_CONFIG = {
    'host': 'localhost',
    'port': '5432',
    'user': 'postgres',
    'password': 'postgres',
    'dbname': 'estok',
    'api_key': '' 
}

def get_user_config_path():
    """Get the path to the writable config file in User AppData."""
    if os.name == 'nt':
        app_data = os.environ.get('LOCALAPPDATA')
        if not app_data:
            app_data = os.path.expanduser('~\\AppData\\Local')
    else:
        app_data = os.path.expanduser('~/.local/share')
    
    estok_dir = os.path.join(app_data, 'Estok')
    if not os.path.exists(estok_dir):
        try:
            os.makedirs(estok_dir)
        except OSError:
            pass
    
    return os.path.join(estok_dir, 'db_config.json')

def get_install_config_path():
    """Get the path to the bundled reference config file."""
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base_dir, 'db_config.json')

def load_config():
    """Load configuration: User Config > Bundled Config > Defaults. Also ensures API Key exists."""
    config = DEFAULT_CONFIG.copy()
    
    # 1. Try User Config (AppData)
    user_path = get_user_config_path()
    if os.path.exists(user_path):
        try:
            with open(user_path, 'r', encoding='utf-8') as f:
                user_config = json.load(f)
                config.update(user_config)
        except Exception as e:
            print(f"Error loading user config: {e}")

    # 2. If User Config didn't specific keys but Install Config does? 
    # Actually, standard pattern is User Config overrides everything.
    # But if User Config is missing, we check Install Config.
    # The current logic was a bit simplified. Let's stick to "Load User, if not, Load Install, if not Default".
    # BUT, we also want to Merge defaults if keys are missing.
    
    # Let's refine: Start with Defaults. Update with Install. Update with User.
    
    install_path = get_install_config_path()
    if os.path.exists(install_path):
        try:
            with open(install_path, 'r', encoding='utf-8') as f:
                install_config = json.load(f)
                config.update(install_config)
        except Exception as e:
            print(f"Error loading bundled config: {e}")

    if os.path.exists(user_path):
        try:
            with open(user_path, 'r', encoding='utf-8') as f:
                user_config = json.load(f)
                config.update(user_config)
        except Exception as e:
            print(f"Error loading user config: {e}")

    # Ensure API Key exists
    if not config.get('api_key'):
        # Generate new Key
        new_key = secrets.token_hex(32) # 64 characters
        config['api_key'] = new_key
        # Save it immediately to User Config so it persists
        save_config(config)

    return config

def save_config(config):
    """Save configuration to User Config (AppData). Returns (success, message)."""
    try:
        user_path = get_user_config_path()
        with open(user_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=4, ensure_ascii=False)
        return True, "Configuration saved successfully."
    except Exception as e:
        print(f"Error saving config: {e}")
        return False, str(e)



def get_db_uri():
    """Construct SQLAlchemy URI from config with URL encoding for credentials."""
    config = load_config()
    
    user = urllib.parse.quote_plus(config.get('user', ''))
    password = urllib.parse.quote_plus(config.get('password', ''))
    host = config.get('host', 'localhost')
    port = config.get('port', '5432')
    dbname = config.get('dbname', 'estok')
    
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"

def get_api_key():
    """Get the current API Key."""
    config = load_config()
    return config.get('api_key', '')
