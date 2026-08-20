// Captures a few screens in a given browser language, to check the app
// follows the locale rather than the build.
const { chromium } = require('playwright-core');
const lang = process.argv[2] || 'en-US';
const OUT = process.argv[3];
const shots = [
  ['02-perfil', '#/profile', 1150],
  ['02a-criar-treino', '#/workout-builder', 780],
  ['08a-calendario-semana', '#/calendar/week', 844],
  ['06a-manual-intervalado', '#/import-result/manual-intervals', 844],
];
(async () => {
  require('fs').mkdirSync(OUT, { recursive: true });
  const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium',
    args:['--no-sandbox','--disable-dev-shm-usage', `--lang=${lang}`] });
  for (const [id, route, h] of shots) {
    const ctx = await b.newContext({ viewport:{width:390,height:h},
      deviceScaleFactor:2, locale: lang });
    const p = await ctx.newPage();
    await p.goto('http://127.0.0.1:8099/' + route, { waitUntil:'load' });
    await p.waitForFunction(() => (document.querySelector('flt-glass-pane')
      ?.shadowRoot?.textContent || '').trim().length > 0, null, {timeout:60000});
    await p.waitForTimeout(2200);
    await p.screenshot({ path: `${OUT}/${id}.png` });
    const t = await p.evaluate(() => document.querySelector('flt-glass-pane').shadowRoot.textContent);
    console.log(`${lang} ${id.padEnd(26)} ${t.replace(/\s+/g,' ').slice(0,78)}`);
    await ctx.close();
  }
  await b.close();
})();
