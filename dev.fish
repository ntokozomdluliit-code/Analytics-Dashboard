#!/usr/bin/env fish

function dev-analytics
    echo "🔧 Starting in development mode..."
    echo "Hot reload enabled - server will restart on file changes"
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Start with nodemon for hot-reload
    npx nodemon server.js \
        --watch server.js \
        --watch routes/ \
        --watch middleware/ \
        --watch public/ \
        --ext js,json,html,css \
        --delay 1 \
        --exec "node server.js"
end

if status is-interactive
    dev-analytics
end