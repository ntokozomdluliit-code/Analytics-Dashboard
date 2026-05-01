#!/usr/bin/env fish

function backup-db
    set -l backup_dir "./backups"
    set -l timestamp (date +%Y%m%d_%H%M%S)
    set -l backup_file "$backup_dir/analytics_$timestamp.sql"
    
    mkdir -p $backup_dir
    
    echo "📦 Backing up database..."
    
    if pg_dump -U dashboard analytics > $backup_file
        echo "✅ Backup created: $backup_file"
        echo "   Size: "(du -h $backup_file | cut -f1)
        
        # Keep only last 7 backups
        set -l backup_count (ls -1 $backup_dir/analytics_*.sql 2>/dev/null | wc -l)
        if test $backup_count -gt 7
            echo "🧹 Cleaning old backups..."
            ls -t $backup_dir/analytics_*.sql | tail -n +8 | xargs rm
        end
    else
        echo "❌ Backup failed"
        return 1
    end
end

if status is-interactive
    backup-db
end