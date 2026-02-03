import json
import os
import urllib.parse
import sys

# Default Configuration
DEFAULT_CONFIG = {
    'host': 'localhost',
    'port': '5432',
    'user': 'postgres',
    'password': 'postgres',
    'dbname': 'estok'
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
    """Load configuration: User Config > Bundled Config > Defaults."""
    # 1. Try User Config (AppData)
    user_path = get_user_config_path()
    if os.path.exists(user_path):
        try:
            with open(user_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading user config: {e}")

    # 2. Try Install Dir Config (Reference)
    install_path = get_install_config_path()
    if os.path.exists(install_path):
        try:
            with open(install_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading bundled config: {e}")

    # 3. Defaults
    return DEFAULT_CONFIG

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
