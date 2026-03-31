const express = require('express');
const { Server } = require('ws');
const pty = require('node-pty');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(express.static(path.join(__dirname, 'public')));

const server = app.listen(PORT, () => {
    console.log(`✅ Server running at http://localhost:${PORT}`);
});

const wss = new Server({ server });

wss.on('connection', (ws) => {
    const shell = pty.spawn("docker", [
        "exec", "-it", "--user", "HackLab", "hacklab-container", "bash", "-l"
    ], {
        name: "xterm-color",
        cols: 80,
        rows: 30,
        cwd: process.env.HOME,
        env: process.env,
    });

    // Forward data → browser
    shell.on('data', data => {
        if (ws.readyState === ws.OPEN) {
            ws.send(data);
        }
    });

    // Clean up on PTY error
    shell.on('error', err => {
        console.error('PTY error:', err);
        if (ws.readyState === ws.OPEN) ws.close();
    });

    // When the shell exits
    shell.on('exit', (code, signal) => {
        if (ws.readyState === ws.OPEN) {
            ws.send(`\r\n[Shell exited with code=${code} signal=${signal}]\r\n`);
            ws.close();
        }
    });

    // Browser → PTY, but guard against broken pipe
    ws.on('message', msg => {
        try {
            shell.write(msg);
        } catch (err) {
            console.error('Write to PTY failed:', err);
        }
    });

    // Clean up if browser disconnects
    ws.on('close', () => {
        shell.kill();
    });

    // Catch any websocket errors
    ws.on('error', err => {
        console.error('WebSocket error:', err);
        shell.kill();
    });
});

// catch any uncaught exceptions so the server stays up
process.on('uncaughtException', err => {
    console.error('Uncaught exception:', err);
});
process.on('unhandledRejection', err => {
    console.error('Unhandled rejection:', err);
});
