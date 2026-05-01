#!/usr/bin/env fish

function monitor-analytics
    echo "📊 Analytics System Monitor"
    echo "════════════════════════════"
    echo ""
    
    while true
        clear
        echo "📊 Analytics System Status - "(date)
        echo "══════════════════════════════"
        echo ""
        
        # Server status
        echo "🌐 Server Status:"
        if curl -s http://localhost:3001/api/stats >/dev/null 2>&1
            echo "   ✅ Online"
            echo "   📈 Stats: "(curl -s http://localhost:3001/api/stats | jq -c '.stats' 2>/dev/null)
        else
            echo "   ❌ Offline"
        end
        echo ""
        
        # PM2 status
        echo "⚡ PM2 Processes:"
        pm2 list 2>/dev/null | grep -A 5 "analytics"
        echo ""
        
        # Database connections
        echo "🗄️  Database:"
        if pg_isready -q
            set -l db_size (psql -U dashboard -d analytics -t -c "SELECT pg_size_pretty(pg_database_size('analytics'))" 2>/dev/null)
            echo "   ✅ Connected - Size: $db_size"
        else
            echo "   ❌ Disconnected"
        end
        echo ""
        
        # Redis status
        echo "💾 Redis:"
        if redis-cli ping &>/dev/null
            set -l redis_mem (redis-cli info memory | grep used_memory_human | cut -d: -f2)
            echo "   ✅ Connected - Memory: $redis_mem"
        else
            echo "   ❌ Disconnected"
        end
        echo ""
        
        # Active connections
        echo "🔌 Active Connections:"
        set -l ws_connections (ss -tn state established | grep :3001 | wc -l)
        echo "   WebSocket: $ws_connections"
        echo ""
        
        # System resources
        echo "💻 System Resources:"
        echo "   CPU: "(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"%"
        echo "   Memory: "(free -h | grep Mem | awk '{print $3 "/" $2}')
        echo "   Disk: "(df -h ~/analytics-dashboard | tail -1 | awk '{print $5}')
        echo ""
        
        # Recent logs (last 5 lines)
        echo "📝 Recent Logs:"
        tail -5 logs/combined.log 2>/dev/null | while read -l line
            echo "   $line"
        end
        
        echo ""
        echo "Press Ctrl+C to exit"
        sleep 5
    end
end

if status is-interactive
    monitor-analytics
end