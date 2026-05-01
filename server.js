
const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const https = require("https");
const path = require("path");

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server: server, path: "/ws" });

app.use(express.static("public"));

let eventCount = 0;
const clients = new Set();
let realThreats = [];

// ===== FETCH REAL THREAT DATA =====
function fetchRealThreats() {
    console.log("\n🔄 Fetching real threat intelligence...");
    
    // Source 1: Phishing.Database
    https.get("https://raw.githubusercontent.com/Phishing-Database/Phishing.Database/master/phishing-links-ACTIVE-NOW.txt", (res) => {
        let data = "";
        res.on("data", chunk => data += chunk);
        res.on("end", () => {
            const urls = data.split("\n").filter(line => line.startsWith("http")).slice(0, 100);
            console.log(`✅ Phishing.Database: ${urls.length} URLs loaded`);
            
            urls.forEach(url => {
                try {
                    const domain = new URL(url.trim()).hostname;
                    realThreats.push({
                        url: url.trim(),
                        domain: domain,
                        type: "phishing",
                        source: "Phishing.Database"
                    });
                } catch(e) {}
            });
        });
    });
    
    // Source 2: Criminal IP Daily Feed
    https.get("https://raw.githubusercontent.com/criminalip/Daily-Mal-Phishing/main/2026-04-19.csv", (res) => {
        let data = "";
        res.on("data", chunk => data += chunk);
        res.on("end", () => {
            const lines = data.split("\n").slice(1);
            console.log(`✅ Criminal IP: ${lines.length} entries loaded`);
            
            lines.forEach(line => {
                const parts = line.split(",");
                if (parts.length >= 2) {
                    const url = parts[1]?.trim();
                    const score = parts[2]?.trim();
                    if (url && url.startsWith("http") && (score === "Critical" || score === "Dangerous")) {
                        try {
                            realThreats.push({
                                url: url,
                                domain: new URL(url).hostname,
                                type: "malware/phishing",
                                severity: score,
                                source: "CriminalIP"
                            });
                        } catch(e) {}
                    }
                }
            });
        });
    });
}

// Fetch every 30 minutes
fetchRealThreats();
setInterval(fetchRealThreats, 30 * 60 * 1000);

// ===== SEND EVENTS TO DASHBOARD =====
setInterval(() => {
    eventCount++;
    
    let event;
    
    // Mix real threats with test data
    if (realThreats.length > 0 && Math.random() > 0.3) {
        const threat = realThreats[Math.floor(Math.random() * realThreats.length)];
        event = {
            type: "threat_detected",
            domain: threat.domain,
            url: threat.url,
            severity: threat.severity || "suspicious",
            source: threat.source,
            timestamp: Date.now()
        };
    } else {
        event = {
            type: ["pageview", "click", "form_submission"][Math.floor(Math.random() * 3)],
            domain: ["suspicious-site.com", "fake-login.net"][Math.floor(Math.random() * 2)],
            timestamp: Date.now()
        };
    }
    
    const message = JSON.stringify({
        type: "event",
        data: event,
        count: eventCount,
        totalThreats: realThreats.length
    });
    
    clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
    
    console.log(`📊 Event #${eventCount}: ${event.type} - ${event.domain} [${realThreats.length} threats loaded]`);
}, 2000);

// WebSocket
wss.on("connection", (ws) => {
    clients.add(ws);
    console.log("✅ Dashboard connected. Total:", clients.size);
    
    ws.send(JSON.stringify({
        type: "stats",
        totalThreats: realThreats.length
    }));
    
    ws.on("close", () => {
        clients.delete(ws);
    });
});

app.get("/api/threats", (req, res) => {
    res.json({
        total: realThreats.length,
        sample: realThreats.slice(0, 20)
    });
});

app.get("/api/health", (req, res) => {
    res.json({ status: "ok", events: eventCount, threats: realThreats.length });
});

app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "dashboard.html"));
});

server.listen(3001, () => {
    console.log("🚀 Server running on http://localhost:3001");
    console.log("📡 Fetching real threat data...\n");
});

