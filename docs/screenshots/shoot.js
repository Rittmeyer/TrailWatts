const { chromium } = require('playwright-core');
const fs = require('fs');

const BASE = 'http://127.0.0.1:8099/';
const OUT = process.argv[2] || '/home/user/TrailWatts/docs/screenshots';

const shots = [
  { id: '01-splash',                    route: '#/splash', splash: true },
  { id: '01a-login',                    route: '#/auth' },
  { id: '01b-criar-conta',              route: '#/auth', click: 'Criar conta', h: 700 },
  { id: '02-perfil',                    route: '#/profile', h: 1150 },
  { id: '02a-criar-treino',             route: '#/workout-builder', h: 780 },
  { id: '02a2-onde-treinar',            route: '#/workout-builder/map' },
  { id: '03-treino-do-dia',             route: '#/home' },
  { id: '04-rota-no-mapa',              route: '#/route-map', h: 760 },
  { id: '05-editar-rota',               route: '#/route-edit', h: 820 },
  { id: '06-importar-resultado',        route: '#/import-result', h: 900 },
  { id: '06a-manual-intervalado',       route: '#/import-result/manual-intervals' },
  { id: '06b-manual-continuo',          route: '#/import-result/manual-continuous' },
  { id: '07-historico',                 route: '#/history' },
  { id: '08a-calendario-semana',        route: '#/calendar/week' },
  { id: '08b-calendario-dia-concluido', route: '#/calendar/week', click: '21' },
  { id: '08c-calendario-mes',           route: '#/calendar/month', h: 900 },
  { id: 'web-landing',                  route: '#/', w: 1440, h: 900, scale: 1 },
];

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium',
    // The app follows the browser language, so the canonical set is pinned
    // to pt-BR; docs/screenshots/en holds the same screens in English.
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--lang=pt-BR'],
  });

  for (const s of shots) {
    const ctx = await browser.newContext({
      viewport: { width: s.w || 390, height: s.h || 844 },
      deviceScaleFactor: s.scale || 2,
      locale: 'pt-BR',
    });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e)));

    await page.goto(BASE + s.route, { waitUntil: 'load' });

    // Flutter's html renderer paints inside flt-glass-pane's shadow root,
    // so readiness has to be probed through it - document.body is empty.
    const painted = (needle) =>
      page.waitForFunction(
        (n) => {
          const gp = document.querySelector('flt-glass-pane');
          if (!gp || !gp.shadowRoot) return false;
          const t = gp.shadowRoot.textContent || '';
          return n ? t.includes(n) : t.trim().length > 0;
        },
        needle, { timeout: 60000 }
      );

    if (s.splash) {
      // Splash self-navigates after 1.1s - shoot the instant it paints.
      await painted('TRAILWATT');
    } else {
      await painted(null);
      await page.waitForTimeout(1800); // fonts + map layers settle
      if (s.click) {
        // Text lives in flt-scene; flt-ruler-host holds invisible measuring
        // copies, so resolve the painted node and click its center.
        // Painted paragraphs report a collapsed 0x0 box, but their x/y is the
        // real text origin - nudge inside it to land on the tap target.
        const box = await page.evaluate((text) => {
          const root = document.querySelector('flt-glass-pane').shadowRoot;
          for (const el of root.querySelectorAll('flt-paragraph')) {
            if ((el.textContent || '').trim() !== text) continue;
            if (el.closest('flt-ruler-host')) continue;
            const r = el.getBoundingClientRect();
            return { x: r.x + 8, y: r.y + 8 };
          }
          return null;
        }, s.click);
        if (!box) throw new Error(`no painted node for "${s.click}" in ${s.id}`);
        await page.mouse.click(box.x, box.y);
        await page.waitForTimeout(900);
      }
    }

    const file = `${OUT}/${s.id}.png`;
    await page.screenshot({ path: file });
    const txt = (await page.evaluate(() =>
      (document.querySelector('flt-glass-pane').shadowRoot.textContent || '')
    )).replace(/\s+/g, ' ').trim();
    console.log(`${s.id.padEnd(32)} ${txt.slice(0, 95)}`);
    if (errors.length) console.log(`   !! ${errors[0].slice(0, 160)}`);
    await ctx.close();
  }

  await browser.close();
  console.log('\nDONE ->', OUT);
})();
