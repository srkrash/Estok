# Implementation Plan - Server Manager GUI

## Goal
Create a Desktop GUI wrapper for the Flask Server to manage its lifecycle, database connections, and background execution via System Tray.

## User Review Required
> [!NOTE]
> This implementation requires additional Python libraries: `pystray` and `Pillow`.

## Proposed Changes

### Documentation
#### [MODIFY] [.agent/doc.md](file:///e:/Dev/Estok/.agent/doc.md)
- Add "Server Manager" component to Architecture.

#### [MODIFY] [.agent/todo.md](file:///e:/Dev/Estok/.agent/todo.md)
- Add tasks for Server Interface (GUI, DB Init, Connectivity Test, Tray).

### Backend (Python/Flask)
#### [NEW] [estok-py/server_gui.py](file:///e:/Dev/Estok/estok-py/server_gui.py)
- **GUI Framework**: `tkinter` (Standard Python).
- **Tray Icon**: `pystray`.
- **Features**:
    - **Server Status**: Start/Stop server thread.
    - **DB Tools**:
        - "Test Connection": Pings DB.
        - "Initialize Database": Runs `schema.sql`.
    - **Window Management**:
        - Close (X) -> Minimize to Tray.
        - Double-click Tray -> Restore Window.
        - Quit option in Tray -> Full exit.

## Verification Plan
### Manual Verification
1. **Install Dependencies**: `pip install pystray Pillow`
2. **Run GUI**: `python estok-py/server_gui.py`
3. **Test DB Connection**: Click "Test Connection" button.
4. **Init DB**: Click "Initialize Database" and verify tables in Postgres.
5. **Start Server**: Verify status indicator changes to "Running" (Green).
6. **Minimize**: Close window, verify icon in tray.
7. **Restore**: Double-click tray icon.
8. **Quit**: Use Tray menu to Quit.
