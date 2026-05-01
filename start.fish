#!/usr/bin/env fish

function start-analytics
    echo "🚀 Starting Analytics Dashboard System..."
    echo ""
    
    # Check Redis
    if redis-cli ping &>/dev/null
        echo "✅ Redis is running"
    else
        echo "❌ Redis is not running. Starting..."
        sudo systemctl start redis
        or begin
            echo "❌ Failed to start Redis"
            return 1
        end
    end
    
    # Check PostgreSQL
    if pg_isready -q
        echo "✅ PostgreSQL is running"
    else
        echo "❌ PostgreSQL is not running. Starting..."
        sudo systemctl start postgresql
        or begin
            echo "❌ Failed to start PostgreSQL"
            return 1
        end
    end
    
    # Start with PM2
    echo "📡 Starting analytics server..."
    pm2 start ecosystem.config.js
    or begin
        echo "❌ Failed to start via PM2"
        return 1
    end
    
    echo ""
    echo "✅ System ready!"
    echo "📊 Dashboard: http://localhost:3001"
    echo "📡 WebSocket: ws://localhost:3001"
    echo ""
    echo "Use 'pm2 logs analytics-server' to view logs"
    echo "Use './stop.fish' to stop all services"
    echo "Use 'pm2 monit' for process monitoring"
end

# Run if executed directly
if status is-interactive
    start-analytics
end