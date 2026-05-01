#!/usr/bin/env fish

function test-system
    echo "🔍 Testing Analytics System Components..."
    echo "═══════════════════════════════════════"
    echo ""
    
    # Test Node.js
    if command -v node &>/dev/null
        echo "✅ Node.js: "(node --version)
    else
        echo "❌ Node.js not found"
    end
    
    # Test npm
    if command -v npm &>/dev/null
        echo "✅ npm: "(npm --version)
    else
        echo "❌ npm not found"
    end
    
    # Test Redis
    if redis-cli ping &>/dev/null
        echo "✅ Redis: Connected"
    else
        echo "❌ Redis: Not running - run: sudo systemctl start redis"
    end
    
    # Test PostgreSQL
    if pg_isready -q
        echo "✅ PostgreSQL: Connected"
        
        # Test database access
        if psql -U dashboard -d analytics -c "SELECT 1" &>/dev/null
            echo "✅ Database: Accessible"
        else
            echo "❌ Database: Cannot access"
            echo "   Check credentials in .env file"
        end
    else
        echo "❌ PostgreSQL: Not running - run: sudo systemctl start postgresql"
    end
    
    # Test server
    if curl -s http://localhost:3001/api/stats >/dev/null 2>&1
        echo "✅ Server: Running on port 3001"
        echo "   Stats endpoint: "(curl -s http://localhost:3001/api/stats | jq . 2>/dev/null || echo "Response received")
    else
        echo "⚠️  Server: Not running on port 3001"
    end
    
    # Check PM2
    if command -v pm2 &>/dev/null
        echo "✅ PM2: "(pm2 --version)
        
        if pm2 list | grep -q "analytics-server"
            echo "✅ Analytics Server: Running via PM2"
            pm2 list
        else
            echo "⚠️  Analytics Server: Not running via PM2"
            echo "   Run: ./start.fish"
        end
    else
        echo "⚠️  PM2: Not installed (optional)"
        echo "   Install with: sudo npm install -g pm2"
    end
    
    # Check disk space
    set disk_usage (df -h ~/analytics-dashboard | tail -1 | awk '{print $5}')
    echo "💾 Disk usage: $disk_usage"
    
    # Check memory
    set mem_usage (free -h | grep Mem | awk '{print $3 "/" $2}')
    echo "🧠 Memory: $mem_usage"
    
    echo ""
    echo "═══════════════════════════════════════"
    echo "System check complete!"
    
    # Suggestions
    if not pg_isready -q; or not redis-cli ping &>/dev/null
        echo ""
        echo "💡 Quick fix: Run these commands:"
        test ! (pg_isready -q); and echo "   sudo systemctl start postgresql"
        test ! (redis-cli ping &>/dev/null); and echo "   sudo systemctl start redis"
    end
end

if status is-interactive
    test-system
end