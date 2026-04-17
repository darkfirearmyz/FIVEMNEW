'use strict';

const app          = document.getElementById('app');
const engineBar    = document.getElementById('engineBar');
const bodyBar      = document.getElementById('bodyBar');
const engineVal    = document.getElementById('engineVal');
const bodyVal      = document.getElementById('bodyVal');
const playerSelect = document.getElementById('playerSelect');
const billBtn      = document.getElementById('billBtn');
const closeBtn     = document.getElementById('closeBtn');

let prices = {};

// ── Receive data from Lua ──────────────────────────────────────

window.addEventListener('message', (e) => {
    const data = e.data;

    if (data.action === 'openMenu') {
        prices = data.prices || {};

        // Health bars (0–1000)
        const eng  = Math.max(0, Math.min(1000, data.engineHealth));
        const body = Math.max(0, Math.min(1000, data.bodyHealth));

        engineBar.style.width = (eng / 10) + '%';
        bodyBar.style.width   = (body / 10) + '%';
        engineVal.textContent = eng;
        bodyVal.textContent   = body;

        // Prices
        ['engine','body','tyres','full'].forEach(part => {
            const el = document.getElementById('price-' + part);
            if (el) el.textContent = '$' + (prices[part] || 0);
        });

        // Nearby players
        playerSelect.innerHTML = '<option value="">— Select Nearby Player —</option>';
        (data.nearbyPlayers || []).forEach(p => {
            const opt = document.createElement('option');
            opt.value       = p.id;
            opt.textContent = p.name + ' (ID: ' + p.id + ')';
            playerSelect.appendChild(opt);
        });

        app.classList.remove('hidden');
    }

    if (data.action === 'closeMenu') {
        app.classList.add('hidden');
    }
});

// ── Repair buttons ────────────────────────────────────────────

document.querySelectorAll('.repair-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const part = btn.dataset.part;
        fetch('https://qb-mechanic/repairPart', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ part }),
        });
    });
});

// ── Bill button ───────────────────────────────────────────────

billBtn.addEventListener('click', () => {
    const targetId = playerSelect.value;
    const part     = document.getElementById('billPart').value;

    if (!targetId) {
        alert('Select a player to bill.');
        return;
    }

    fetch('https://qb-mechanic/billPlayer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId, part }),
    });
});

// ── Close button ──────────────────────────────────────────────

closeBtn.addEventListener('click', () => {
    app.classList.add('hidden');
    fetch('https://qb-mechanic/closeMenu', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
});
