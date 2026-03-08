# Test Scripts - Development Tools

## Overview

These test scripts are **development and testing tools** included in the repository to help with:
- Quick backend testing
- Debugging issues
- CI/CD integration
- Onboarding new developers

## Scripts Included

### `test_backend.sh`
- Tests all backend endpoints
- Verifies API is working correctly
- **Usage**: `./test_backend.sh`

### `test_image.sh`
- Tests image prediction endpoint
- **Usage**: `./test_image.sh /path/to/image.jpg`

### `debug_crops.py`
- Debugs crop recommendation matching
- Helps troubleshoot CSV data issues
- **Usage**: `python debug_crops.py`

### `start_backend.sh`
- Quick start script for backend
- Handles virtual environment setup
- **Usage**: `./start_backend.sh`

## For Production Deployment

### Option 1: Keep Scripts (Recommended)
✅ **Pros:**
- Helpful for maintenance and debugging
- Useful for CI/CD pipelines
- Good for team collaboration

✅ **Best for:** Teams, open-source projects, long-term maintenance

### Option 2: Remove Scripts
If you want a minimal production repo:

1. Add to `.gitignore`:
   ```
   test_*.sh
   debug_*.py
   *_test.py
   ```

2. Or create a separate `scripts/` directory and exclude it

## Recommendation

**Keep the scripts** - They're small, helpful, and don't affect production. They're clearly marked as development tools and can be useful for:
- Troubleshooting production issues
- Testing after deployments
- Onboarding new team members

If you want to exclude them, the `.gitignore` already has commented lines you can uncomment.
