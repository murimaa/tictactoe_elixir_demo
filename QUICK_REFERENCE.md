# app.sh Quick Reference Card

## 🚀 Most Common Commands

```bash
# Daily Development
./app.sh dev-start          # Start development with hot reload
./app.sh dev-logs           # Watch development logs
./app.sh dev-stop           # Stop development

# Pre-commit Quality
./app.sh fix-format         # Auto-fix code formatting
./app.sh quality-check      # Run all quality checks

# Production Deploy
./app.sh release            # Build & test release
./app.sh prod-start         # Start production container
./app.sh health             # Check if app is healthy
./app.sh prod-stop          # Stop production

# Troubleshooting  
./app.sh status             # Show what's running
./app.sh cleanup            # Clean up everything
```

## 📋 All Commands by Category

### 🛠️ Development
| Command | Description |
|---------|-------------|
| `dev-start` | Start development environment with hot reload |
| `dev-stop` | Stop development environment |
| `dev-logs` | Show development logs (follow) |
| `dev-shell` | Open shell in development container |

### ✅ Quality & Testing
| Command | Description |
|---------|-------------|
| `quality-check` | Run all quality checks (format, compile, test, security) |
| `check-format` | Check code formatting only |
| `fix-format` | Auto-fix code formatting |
| `test` | Run tests only |

### 🚀 Production & Build
| Command | Description |
|---------|-------------|
| `build` | Build Docker image |
| `prod-start` | Start production container |
| `prod-stop` | Stop production container |
| `prod-logs` | Show production logs (follow) |
| `release` | Full release pipeline (quality + build + test) |

### 🔧 Utilities
| Command | Description |
|---------|-------------|
| `setup-env` | Setup environment file (.env) |
| `status` | Show comprehensive system status |
| `health` | Check application health |
| `cleanup` | Clean up all resources |
| `help` | Show detailed help |

## 🎯 Common Workflows

### First Time Setup
```bash
./app.sh setup-env          # Create .env file
# Edit .env with your settings
./app.sh release            # Build everything
./app.sh prod-start         # Start production
./app.sh health             # Verify it works
```

### Daily Development
```bash
./app.sh dev-start          # Morning: start development
# ... code all day ...
./app.sh dev-logs           # Debug issues
./app.sh dev-stop           # Evening: stop development
```

### Before Git Commit
```bash
./app.sh fix-format         # Fix any formatting issues
./app.sh quality-check      # Run all quality checks
git add . && git commit     # Safe to commit
```

### Production Release
```bash
./app.sh quality-check      # Ensure code quality
./app.sh release            # Build release version
./app.sh prod-start         # Deploy locally
./app.sh health             # Verify deployment
```

### CI/CD Pipeline
```bash
./app.sh release --push-image    # Build, test, and push to registry
```

### Troubleshooting
```bash
./app.sh status             # See what's running
./app.sh health --verbose   # Detailed health check
./app.sh cleanup            # Nuclear option: clean everything
```

## 🏷️ Useful Options

| Option | Description |
|--------|-------------|
| `--skip-tests` | Skip test execution |
| `--push-image` | Push image to registry (for `release`) |
| `--verbose, -v` | Show verbose output |

## 🔗 Quick Links

- **Full Help**: `./app.sh help`
- **System Status**: `./app.sh status`
- **Migration Guide**: See `MIGRATION.md`
- **Full Documentation**: See `DEPLOYMENT.md`

## 🆘 Emergency Commands

```bash
# Something is broken, start fresh
./app.sh cleanup
./app.sh setup-env
./app.sh dev-start

# Port 4000 is busy
sudo lsof -i :4000          # Find what's using it
./app.sh cleanup            # Clean up our stuff

# Can't remember what's running
./app.sh status             # Shows everything

# App won't start
./app.sh prod-logs          # Check what's wrong
```

---

💡 **Tip**: Bookmark this file and keep it handy during development!