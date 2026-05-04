#!/bin/bash

# Fix QR Codes Script
# This script updates all tables with proper QR code data

echo "🚀 Fixing QR Codes for All Tables..."
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create a .env file with MONGODB_URI and WEB_APP_URL"
    exit 1
fi

# Run the fix script
node src/utils/fix-table-qr-codes.js

echo ""
echo "✅ Done! You can now download QR codes from the admin panel."
