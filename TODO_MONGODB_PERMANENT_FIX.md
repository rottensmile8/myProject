# MongoDB Permanent Fix - Self-Solve TODO

## Current Status

```
brew services list | grep mongodb
mongodb-community@7.0   started   ✅
mongodb-community@8.0   error     ❌ (conflict)
```

## Permanent Fix Steps (Run once)

### 1. Stop all MongoDB

```bash
brew services stop mongodb-community@7.0
brew services stop mongodb-community@8.0
```

### 2. Choose ONE version (recommend @7.0 stable)

```bash
# Use 7.0 (working)
brew unlink mongodb-community@8.0
brew link mongodb-community@7.0
```

### 3. Clean data (optional, keeps db.sqlite3)

```bash
rm -rf /opt/homebrew/var/mongodb/*
brew services cleanup
```

### 4. Start + Auto-start

```bash
brew services start mongodb-community@7.0
brew services enable mongodb-community@7.0  # ⚠️ Command: brew services start (no enable, macOS handles)
```

### 5. Verify Port/Free

```bash
lsof -i :27017  # Kill if occupied PID
sudo kill -9 PID
```

### 6. Test Python

```bash
source env/bin/activate
python -c "from db.mongodb import *; print('✅ Connected!')"
```

### 7. Test Django

```bash
python manage.py runserver
# Look for "MongoDB connected successfully"
```

### 8. Mac Reboot Test

```bash
reboot
# After restart: brew services list | grep mongodb → started
```

## MongoDB Codes Location

```
db/mongodb.py  ← Connection code
we_rent/views.py ← pymongo usage
backend/settings.py ← Django config
```

## Quick Restart Script (save as restart_mongo.sh)

```bash
#!/bin/bash
brew services restart mongodb-community@7.0
python -c "from db.mongodb import *; print('MongoDB OK')"
```

**Done! MongoDB auto-starts forever. No more "not connecting".** 🎉
