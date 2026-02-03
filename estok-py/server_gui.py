import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
import threading
import pystray
from PIL import Image, ImageDraw
import sys
import os
import logging
import logging
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from sqlalchemy import text
from werkzeug.serving import make_server
import config_manager

# Add current directory to path to import main
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from main import app, db
except ImportError as e:
    print(f"Error importing Flask app: {e}")
    sys.exit(1)

class ServerManagerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Estok Server Manager")
        self.root.geometry("500x650")
        try:
            self.root.iconbitmap("logo_green.ico")
        except Exception as e:
            print(f"Icon load error: {e}")
        self.root.protocol("WM_DELETE_WINDOW", self.hide_window)

        # Server State
        self.server_thread = None
        self.server_running = False
        self.flask_server = None

        # UI Layout
        self.create_widgets()
        
        # Tray Icon
        self.tray_icon = None
        self.setup_tray_icon()
        
        # Start Tray in separate thread
        self.tray_thread = threading.Thread(target=self.run_tray, daemon=True)
        self.tray_thread.start()

        self.log("Ready.")

    def create_widgets(self):
        # Status Frame
        status_frame = tk.Frame(self.root, pady=10)
        status_frame.pack(fill=tk.X)
        
        tk.Label(status_frame, text="Server Status:").pack(side=tk.LEFT, padx=10)
        self.status_indicator = tk.Label(status_frame, text="STOPPED", fg="red", font=("Arial", 10, "bold"))
        self.status_indicator.pack(side=tk.LEFT)

        # Configuration Frame
        self.create_config_widgets()

        # Controls Frame
        controls_frame = tk.LabelFrame(self.root, text="Server Controls", padx=10, pady=10)
        controls_frame.pack(fill=tk.X, padx=10, pady=5)

        self.btn_start = tk.Button(controls_frame, text="Start Server", command=self.start_server, bg="#dddddd")
        self.btn_start.grid(row=0, column=0, padx=5, pady=5, sticky="ew")

        self.btn_stop = tk.Button(controls_frame, text="Stop Server", command=self.stop_server, state=tk.DISABLED, bg="#dddddd")
        self.btn_stop.grid(row=0, column=1, padx=5, pady=5, sticky="ew")

        self.btn_open_browser = tk.Button(controls_frame, text="Open in Browser", command=self.open_browser, bg="#dddddd")
        self.btn_open_browser.grid(row=0, column=2, padx=5, pady=5, sticky="ew")

        # Database Frame
        db_frame = tk.LabelFrame(self.root, text="Database Tools", padx=10, pady=10)
        db_frame.pack(fill=tk.X, padx=10, pady=5)

        tk.Button(db_frame, text="Test Connection", command=self.test_db_connection).pack(side=tk.LEFT, padx=5, expand=True, fill=tk.X)
        tk.Button(db_frame, text="Initialize Database (Schema)", command=self.init_database).pack(side=tk.LEFT, padx=5, expand=True, fill=tk.X)

        # Log Area
        log_frame = tk.Frame(self.root, padx=10, pady=5)
        log_frame.pack(fill=tk.BOTH, expand=True)
        tk.Label(log_frame, text="Logs:").pack(anchor=tk.W)
        self.log_area = scrolledtext.ScrolledText(log_frame, height=10, state='disabled', font=("Consolas", 9))
        self.log_area.pack(fill=tk.BOTH, expand=True)

    def create_config_widgets(self):
        config_frame = tk.LabelFrame(self.root, text="Database Configuration", padx=10, pady=10)
        config_frame.pack(fill=tk.X, padx=10, pady=5)

        # Grid layout for config
        config = config_manager.load_config()

        tk.Label(config_frame, text="Host:").grid(row=0, column=0, sticky="e", padx=5, pady=2)
        self.entry_host = tk.Entry(config_frame)
        self.entry_host.insert(0, config.get('host', 'localhost'))
        self.entry_host.grid(row=0, column=1, sticky="ew", padx=5, pady=2)

        tk.Label(config_frame, text="Port:").grid(row=0, column=2, sticky="e", padx=5, pady=2)
        self.entry_port = tk.Entry(config_frame, width=10)
        self.entry_port.insert(0, config.get('port', '5432'))
        self.entry_port.grid(row=0, column=3, sticky="ew", padx=5, pady=2)

        tk.Label(config_frame, text="User:").grid(row=1, column=0, sticky="e", padx=5, pady=2)
        self.entry_user = tk.Entry(config_frame)
        self.entry_user.insert(0, config.get('user', 'postgres'))
        self.entry_user.grid(row=1, column=1, sticky="ew", padx=5, pady=2)

        tk.Label(config_frame, text="Password:").grid(row=1, column=2, sticky="e", padx=5, pady=2)
        self.entry_pass = tk.Entry(config_frame, show="*")
        self.entry_pass.insert(0, config.get('password', 'postgres'))
        self.entry_pass.grid(row=1, column=3, sticky="ew", padx=5, pady=2)

        tk.Label(config_frame, text="DB Name:").grid(row=2, column=0, sticky="e", padx=5, pady=2)
        self.entry_dbname = tk.Entry(config_frame)
        self.entry_dbname.insert(0, config.get('dbname', 'estok'))
        self.entry_dbname.grid(row=2, column=1, sticky="ew", padx=5, pady=2)

        tk.Label(config_frame, text="API Key:").grid(row=3, column=0, sticky="e", padx=5, pady=2)
        self.entry_api_key = tk.Entry(config_frame)
        self.entry_api_key.insert(0, config.get('api_key', ''))
        self.entry_api_key.grid(row=3, column=1, columnspan=3, sticky="ew", padx=5, pady=2)

        tk.Button(config_frame, text="Save Configuration", command=self.save_configuration, bg="#dddddd").grid(row=4, column=0, columnspan=4, pady=10, sticky="ew")

        config_frame.columnconfigure(1, weight=1)

    def save_configuration(self):
        config = {
            'host': self.entry_host.get(),
            'port': self.entry_port.get(),
            'user': self.entry_user.get(),
            'password': self.entry_pass.get(),
            'dbname': self.entry_dbname.get(),
            'api_key': self.entry_api_key.get()
        }
        
        success, msg = config_manager.save_config(config)
        
        if success:
            self.log(msg)
            # Update running app config
            new_uri = config_manager.get_db_uri()
            app.config['SQLALCHEMY_DATABASE_URI'] = new_uri
            self.log("App config updated (Runtime). Please restart server if running.")
            messagebox.showinfo("Config Saved", msg + "\nIf server is running, please restart it.")
        else:
            self.log(f"Error saving configuration: {msg}")
            messagebox.showerror("Error", f"Failed to save configuration.\n{msg}")

    def log(self, message):
        self.log_area.config(state='normal')
        self.log_area.insert(tk.END, f"{message}\n")
        self.log_area.see(tk.END)
        self.log_area.config(state='disabled')

    def create_image(self):
        # Generate a simple icon
        width = 64
        height = 64
        color1 = (0, 128, 0) # Green
        color2 = (255, 255, 255) # White
        image = Image.new('RGB', (width, height), color1)
        dc = ImageDraw.Draw(image)
        dc.rectangle((width // 4, height // 4, 3 * width // 4, 3 * height // 4), fill=color2)
        return image

    def setup_tray_icon(self):
        try:
            image = Image.open('logo_green_tray.png')
        except Exception:
            image = self.create_image()
            
        menu = pystray.Menu(
            pystray.MenuItem("Show", self.show_window_from_tray, default=True),
            pystray.MenuItem("Quit", self.quit_app)
        )
        self.tray_icon = pystray.Icon("Estok Server", image, "Estok Server Manager", menu)

    def run_tray(self):
        try:
            self.tray_icon.run()
        except Exception as e:
            print(f"Tray error: {e}")

    def hide_window(self):
        self.root.withdraw()
        self.log("Window minimized to tray.")

    def show_window_from_tray(self, icon, item):
        self.root.after(0, self.root.deiconify)

    def quit_app(self, icon, item):
        self.stop_server()
        self.tray_icon.stop()
        self.root.after(0, self.root.destroy)

    # --- Server Logic ---
    def start_server(self):
        if self.server_running:
            return

        self.server_thread = threading.Thread(target=self.run_flask)
        self.server_thread.daemon = True
        self.server_thread.start()
        
        self.server_running = True
        self.status_indicator.config(text="RUNNING", fg="green")
        self.btn_start.config(state=tk.DISABLED)
        self.btn_stop.config(state=tk.NORMAL)
        self.log("Server starting on port 5000...")

    def run_flask(self):
        # Using Werkzeug make_server to have control over stopping
        try:
            self.flask_server = make_server('0.0.0.0', 5000, app, threaded=True)
            self.flask_server.serve_forever()
        except Exception as e:
            self.root.after(0, lambda: self.log(f"Server Error: {e}"))
            self.root.after(0, self.server_stopped)

    def stop_server(self):
        if not self.flask_server:
            return
            
        self.log("Stopping server...")
        self.btn_stop.config(state=tk.DISABLED) # Prevent double click
        
        # Shutdown can block, so run in a thread
        threading.Thread(target=self._shutdown_thread, daemon=True).start()

    def _shutdown_thread(self):
        try:
            if self.flask_server:
                self.flask_server.shutdown()
                self.flask_server = None
        except Exception as e:
            print(f"Error shutting down: {e}")
        finally:
            self.root.after(0, self.server_stopped)

    def server_stopped(self):
        self.server_running = False
        self.status_indicator.config(text="STOPPED", fg="red")
        self.btn_start.config(state=tk.NORMAL)
        self.btn_stop.config(state=tk.DISABLED)
        self.log("Server stopped.")

    def open_browser(self):
        import webbrowser
        webbrowser.open("http://localhost:5000/")

    # --- DB Logic ---
    def test_db_connection(self):
        self.log("Testing DB Connection...")
        try:
            with app.app_context():
                db.session.execute(text('SELECT 1'))
            self.log("SUCCESS: Database Connected!")
            messagebox.showinfo("Database", "Connection Successful!")
        except Exception as e:
            self.log(f"ERROR: {e}")
            messagebox.showerror("Database Error", f"Connection Failed:\n{e}")

    def init_database(self):
        # Locate schema.sql
        # Assuming we are in estok-py, schema is in ../estok-db/schema.sql
        
        if getattr(sys, 'frozen', False):
            # If frozen, we are running from the executable location
            base_dir = os.path.dirname(sys.executable)
        else:
            # Running from source
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            
        schema_path = os.path.join(base_dir, 'estok-db', 'schema.sql')
        
        if not os.path.exists(schema_path):
            self.log(f"Error: Schema file not found at {schema_path}")
            messagebox.showerror("Error", "Schema file not found!")
            return

        if not messagebox.askyesno("Confirm", "This will create the 'estok' database (if missing) and run schema.sql. Continue?"):
            return

        # Step 1: Ensure DB exists
        if not self.create_estok_db():
             return

        # Step 2: Apply Schema
        self.log(f"Reading schema from {schema_path}...")
        try:
            # Try reading with utf-8, fallback to latin-1
            try:
                with open(schema_path, 'r', encoding='utf-8') as f:
                    sql_script = f.read()
            except UnicodeDecodeError:
                with open(schema_path, 'r', encoding='latin-1') as f:
                    sql_script = f.read()

            with app.app_context():
                # Execute simply using SQLAlchemy text() might fail if multiple statements
                # But psycopg2 usually handles it or we split. 
                # Let's try executing as one block first.
                db.session.execute(text(sql_script))
                db.session.commit()
            
            self.log("SUCCESS: Database Initialized (Schema Applied).")
            messagebox.showinfo("Success", "Database Initialized Successfully!")

        except Exception as e:
            self.log(f"DB Init Error: {e}")
            messagebox.showerror("DB Error", f"Failed to initialize:\n{e}")

    def create_estok_db(self):
        """
        Connects to 'postgres' database to check if 'estok' exists, creating it if not.
        Returns True if successful/exists, False on error.
        """
        db_url = app.config['SQLALCHEMY_DATABASE_URI']
        try:
            # Parse the URL to get credentials, but connect to 'postgres'
            # Assuming URL format: postgresql://user:pass@host:port/dbname
            # We can just replace the last part.
            if '/estok' not in db_url:
                self.log("Usage Warning: DATABASE_URL does not seem to point to 'estok'.")
             
            # Construct connection to 'postgres' default DB
            # We use string replacement for simplicity, assuming standard format.
            # A more robust way handles parsing.
            pg_url = db_url.replace('/estok', '/postgres')
            
            conn = psycopg2.connect(pg_url)
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            cur = conn.cursor()
            
            # Check if exists
            cur.execute("SELECT 1 FROM pg_database WHERE datname = 'estok'")
            exists = cur.fetchone()
            
            if not exists:
                self.log("Database 'estok' does not exist. Creating...")
                cur.execute("CREATE DATABASE estok")
                self.log("CREATED Database 'estok'.")
            else:
                self.log("Database 'estok' already exists.")
            
            cur.close()
            conn.close()
            return True

        except Exception as e:
            self.log(f"Error checking/creating DB: {e}")
            messagebox.showerror("DB Creation Error", f"Failed to create database:\n{e}")
            return False

if __name__ == "__main__":
    root = tk.Tk()
    app_gui = ServerManagerApp(root)
    root.mainloop()
