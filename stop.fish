#!/usr/bin/env fish

function stop-analytics
    echo "🛑 Stopping Analytics Dashboard System..."
    
    # Stop PM2 processes
    pm2 stop analytics-server 2>/dev/null
    pm2 delete analytics-server 2>/dev/null
    
    echo "✅ All services stopped"
    echo "Use './start.fish' to restart"
end

if status is-interactive
    stop-analytics
end