// Renders review stills with one bundle and one browser:
//   node scripts/stills.mjs            -> one still per scene at 70% of the scene
//   node scripts/stills.mjs 0.3        -> at 30% of each scene
//   node scripts/stills.mjs 0.7 shot-04-sign-in shot-06-questions
import {bundle} from '@remotion/bundler';
import {openBrowser, renderStill, selectComposition} from '@remotion/renderer';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const videoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [fractionArg, ...only] = process.argv.slice(2);
const fraction = Number(fractionArg ?? 0.7);
const timeline = JSON.parse(fs.readFileSync(path.join(videoRoot, 'out', 'timeline.json'), 'utf8'))
  .filter((scene) => only.length === 0 || only.includes(scene.id));
const outDir = path.join(videoRoot, 'out', 'stills');
fs.mkdirSync(outDir, {recursive: true});

const serveUrl = await bundle({entryPoint: path.join(videoRoot, 'src', 'index.ts'), publicDir: path.join(videoRoot, 'public')});
const puppeteerInstance = await openBrowser('chrome');
const composition = await selectComposition({serveUrl, id: 'OneHealthDemo', puppeteerInstance});
for (const scene of timeline) {
  const frame = scene.start + Math.floor(scene.durationFrames * fraction);
  await renderStill({composition, serveUrl, frame, output: path.join(outDir, `${scene.id}.png`), puppeteerInstance});
  console.log(`${scene.id} @ ${frame}`);
}
await puppeteerInstance.close({silent: true});
