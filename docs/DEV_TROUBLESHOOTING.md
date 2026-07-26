# Development troubleshooting

## AppInspector / “Cannot find context with specified id” on hot restart

These messages are from the **Flutter DevTools debugger** reconnecting after hot restart, not from your app code:

```
AppInspector: Error calling Runtime.evaluate … WipError -32000 Cannot find context
Utilities: Bad state: No running isolate (inspector is not set)
```

If you still see **`Restarted application in …ms`**, the app is fine.

### What to do

1. Prefer **Windows desktop** or **Android emulator** over Chrome while building UI:
   ```bat
   flutter devices
   flutter run -d windows
   ```
2. In VS Code/Cursor, run **“Flutter (Windows)”** from Run and Debug (see `.vscode/launch.json`).
3. After `pubspec.yaml` changes or big refactors, use **full restart**:
   - Stop the app (Ctrl+C)
   - `flutter pub get`
   - `flutter run` again  
   Do not rely on hot restart alone.
4. Ignore inspector errors if the app runs; they do not affect parents/teachers in production.
5. In the Run and Debug panel, pick **Flutter (Windows)** (not Chrome) so DevTools does not attach to a stale web isolate during hot restart.

## PowerShell fails on this machine

Use **cmd** for Flutter commands (already set in `.vscode/settings.json`).
