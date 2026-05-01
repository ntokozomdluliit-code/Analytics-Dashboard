#!/usr/bin/env fish

function setup-analytics
    echo "🛠️  Setting up Analytics Dashboard..."
    echo "════════════════════════════════════"
    echo ""
    
    # Create directory structure
    echo "📁 Creating directory structure..."
    mkdir -p ~/analytics-dashboard/{public,routes,middleware,utils,logs,backups,extension}
    
    # Check dependencies
    echo "🔍 Checking dependencies..."
    
    set -l missing_deps
    
    for dep in node npm redis-cli psql pg_dump
        if not command -v $dep &>/dev/null
            set -a missing_deps $dep
        end
    end
    
    if test (count $missing_deps) -gt 0
        echo "❌ Missing dependencies: $missing_deps"
        echo "Please install them first:"
        echo "  sudo pacman -S nodejs npm redis postgresql"
        return 1
    end
    
    echo "✅ All dependencies found"
    
    # Install npm packages
    echo "📦 Installing npm packages..."
    cd ~/analytics-dashboard
    
    if test -f package.json
        npm install
    else
        npm init -y
        npm install express ws cors pg ioredis dotenv
        npm install -D nodemon
    end
    
    # Setup database schema
    echo "🗄️  Setting up database..."
    if test -f schema.sql
        psql -U dashboard -d analytics -f schema.sql
        echo "✅ Schema applied"
    else
        echo "⚠️  schema.sql not found - skipping"
    end
    
    # Make scripts executable
    echo "🔧 Making scripts executable..."
    chmod +x *.fish
    
    # Create PM2 config
    echo "⚙️  Creating PM2 configuration..."
    if not test -f ecosystem.config.js
        echo "module.exports = {
  apps: [{
    name: 'analytics-server',
    script: 'server.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'development',
      PORT: 3001
    },
    error_file: 'logs/err.log',
    out_file: 'logs/out.log',
    log_file: 'logs/combined.log',
    time: true
  }]
};" > ecosystem.config.js
    end
    
    # Setup PM2 startup
    echo "🚀 Configuring PM2 startup..."
    pm2 startup fish
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .env with your credentials"
    echo "  2. Run: ./start.fish"
    echo "  3. Open: http://localhost:3001"
end

if status is-interactive
    setup-analytics
end