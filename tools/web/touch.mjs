const { chromium } = await import(process.env.PN_PLAYWRIGHT || 'playwright-core');
const out = process.argv[2], mode = process.argv[3] || 'probe';
const b = await chromium.launch({ channel: 'chrome', headless: true, args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 720 }, hasTouch: true, isMobile: false });
const page = await ctx.newPage();
const logs = []; page.on('console', (m) => logs.push(m.text())); page.on('pageerror', (e) => logs.push('PAGEERROR ' + e));
await page.goto('http://127.0.0.1:8493/index.html');
for (let i = 0; i < 120 && !logs.some((l) => l.startsWith('PROBE')); i++) await page.waitForTimeout(500);
await page.waitForTimeout(1500);
const cdp = await ctx.newCDPSession(page);
const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points.map(([x, y], id) => ({ x, y, id, radiusX: 8, radiusY: 8, force: 1 })) });
const last = () => logs.filter((l) => l.startsWith('PROBE')).at(-1);
await page.screenshot({ path: out + '/web-start.png' });
const before = last();
if (mode === 'drive') {
  const [jx, jy] = JSON.parse(process.argv[4]); const [bx, by] = JSON.parse(process.argv[5]);
  // Finger 1 on the joystick, pushed right and held.
  await touch('touchStart', [[jx, jy]]);
  for (let i = 1; i <= 8; i++) { await touch('touchMove', [[jx + i * 10, jy]]); await page.waitForTimeout(30); }
  await page.waitForTimeout(250);
  const moving = last();
  // Finger 2 on the jump button while finger 1 still holds the joystick (multi-touch).
  const mark = logs.length;
  await touch('touchStart', [[jx + 80, jy], [bx, by]]);
  await page.waitForTimeout(220);
  await page.screenshot({ path: out + '/web-two-fingers.png' });
  await page.waitForTimeout(380);
  const air = logs.slice(mark).filter((l) => l.startsWith('PROBE')).map((l) => +/y=(-?\d+)/.exec(l)[1]);
  const jumping = 'lowest y while two fingers are down: ' + Math.min(...air) + ' (floor 571)';
  await touch('touchEnd', [[jx + 80, jy]]);
  await page.waitForTimeout(150);
  await touch('touchEnd', []);
  await page.waitForTimeout(800);
  console.log(JSON.stringify({ before, moving, jumping, after: last() }));
}
console.log('LAST', last(), 'ERRORS', logs.filter((l) => /error/i.test(l)).slice(0, 5));
await b.close();
