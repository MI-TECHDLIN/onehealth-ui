// Collects every input the composition needs into public/generated/ and writes
// src/generated.ts (scene timeline) plus out/captions.srt.
//
// - Old-app screenshots: copied from OAH_OLD_DIR; only the email (#17, #18) and
//   the password (#23) are covered with solid, irreversible bars.
// - New-app material: files in OAH_NEW_DIR named by shot number (01a.png,
//   04b.png, 09-camera.mp4, ...). A missing shot renders a labelled placeholder.
// - Narration: audio/<scene>.wav + .json from scripts/generate_voice.py.
// - Logo: the official SVG from oneaquahealth.eu, cached unmodified in .work/.
import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const videoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const publicGenerated = path.join(videoRoot, 'public', 'generated');
const audioDir = path.join(videoRoot, 'audio');
const outDir = path.join(videoRoot, 'out');
const workDir = path.join(videoRoot, '.work');
const scenes = JSON.parse(fs.readFileSync(path.join(videoRoot, 'src', 'scenes.json'), 'utf8'));
const oldDir = process.env.OAH_OLD_DIR ?? '/workspaces/firstmate/projects/onehealth-ui/docs/current_ui_snippet';
const newDir = process.env.OAH_NEW_DIR ?? '/workspaces/firstmate/projects/onehealth-ui/docs/video-new';
const fps = 30;
const narrationLeadFrames = 12;
const sceneTailFrames = 24;

const LOGO_URL = 'https://www.oneaquahealth.eu/app/uploads/2022/12/OneAquaHealth-Logo.svg';

// Solid redaction boxes in old-screenshot pixels (720x1604 originals).
const REDACTIONS = {
  17: {box: 'x=116:y=276:w=362:h=44', color: '0x123047'}, // account email value
  18: {box: 'x=116:y=276:w=362:h=44', color: '0x506773'}, // account email value (dark theme)
  23: {box: 'x=182:y=1380:w=290:h=58', color: '0x123047'}, // password field
};

const imageExtensions = new Set(['.png', '.jpg', '.jpeg', '.webp']);
const videoExtensions = new Set(['.mp4', '.mov', '.webm', '.m4v']);
const clipShots = new Set([2, 9, 11, 13]);

const fail = (message) => {
  console.error(message);
  process.exit(1);
};

const run = (command, args) => {
  const result = spawnSync(command, args, {stdio: 'inherit'});
  if (result.status !== 0) fail(`${command} failed with exit code ${result.status}`);
};

const dimensions = (file) => {
  const result = spawnSync('ffprobe', ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height', '-of', 'csv=p=0', file], {encoding: 'utf8'});
  if (result.status !== 0) fail(`ffprobe failed for ${file}`);
  const [width, height] = result.stdout.trim().split(',').map(Number);
  return {width, height};
};

if (!fs.existsSync(oldDir)) fail(`Old-app screenshot directory is missing: ${oldDir}`);
if (!fs.existsSync(audioDir)) fail('Narration is missing: run `npm run audio` first.');

fs.rmSync(publicGenerated, {recursive: true, force: true});
for (const sub of ['old', 'new', 'audio']) fs.mkdirSync(path.join(publicGenerated, sub), {recursive: true});
fs.mkdirSync(outDir, {recursive: true});
fs.mkdirSync(workDir, {recursive: true});

// Logo: official file, downloaded once and never edited.
const cachedLogo = path.join(workDir, 'OneAquaHealth-Logo.svg');
if (!fs.existsSync(cachedLogo)) run('curl', ['--fail', '--silent', '--show-error', '--location', '--output', cachedLogo, LOGO_URL]);
fs.copyFileSync(cachedLogo, path.join(publicGenerated, 'oneaquahealth-logo.svg'));

// Old app: 24 screenshots, numbered in filename sort order.
const oldFiles = fs.readdirSync(oldDir)
  .filter((name) => imageExtensions.has(path.extname(name).toLowerCase()))
  .sort((a, b) => a.localeCompare(b));
if (oldFiles.length !== 24) fail(`Expected 24 old-app screenshots, found ${oldFiles.length} in ${oldDir}`);
oldFiles.forEach((name, offset) => {
  const index = offset + 1;
  const source = path.join(oldDir, name);
  const destination = path.join(publicGenerated, 'old', `old-${String(index).padStart(2, '0')}.png`);
  const redaction = REDACTIONS[index];
  if (redaction) {
    run('ffmpeg', ['-y', '-hide_banner', '-loglevel', 'error', '-i', source,
      '-vf', `drawbox=${redaction.box}:color=${redaction.color}:t=fill`, '-frames:v', '1', destination]);
  } else {
    fs.copyFileSync(source, destination);
  }
});

// New app: group files by their leading shot number.
const byShot = new Map();
if (fs.existsSync(newDir)) {
  for (const name of fs.readdirSync(newDir).sort((a, b) => a.localeCompare(b))) {
    const extension = path.extname(name).toLowerCase();
    if (!imageExtensions.has(extension) && !videoExtensions.has(extension)) continue;
    const match = name.match(/^0*(\d{1,2})(?=[^0-9]|$)/);
    if (!match) continue;
    const shot = Number(match[1]);
    byShot.set(shot, [...(byShot.get(shot) ?? []), name]);
  }
}

const newAssetsFor = (shot) => {
  const names = byShot.get(shot) ?? [];
  const isClip = (name) => videoExtensions.has(path.extname(name).toLowerCase());
  const clips = names.filter(isClip);
  const stills = names.filter((name) => !isClip(name));
  const chosen = clipShots.has(shot) && clips.length > 0 ? clips : stills;
  return chosen.map((name, index) => {
    const extension = path.extname(name).toLowerCase();
    const stem = `shot-${String(shot).padStart(2, '0')}-${String(index + 1).padStart(2, '0')}`;
    const source = path.join(newDir, name);
    if (isClip(name)) {
      const destination = path.join(publicGenerated, 'new', `${stem}.mp4`);
      run('ffmpeg', ['-y', '-hide_banner', '-loglevel', 'error', '-i', source, '-an',
        '-c:v', 'libx264', '-crf', '18', '-preset', 'fast', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', destination]);
      return {type: 'video', src: `generated/new/${stem}.mp4`, source: name, ...dimensions(destination)};
    }
    const normalized = extension === '.jpeg' ? '.jpg' : extension;
    fs.copyFileSync(source, path.join(publicGenerated, 'new', `${stem}${normalized}`));
    return {type: 'image', src: `generated/new/${stem}${normalized}`, source: name, ...dimensions(source)};
  });
};

const srtTime = (milliseconds) => {
  const ms = Math.max(0, Math.round(milliseconds));
  const pad = (value, size = 2) => String(value).padStart(size, '0');
  return `${pad(Math.floor(ms / 3_600_000))}:${pad(Math.floor(ms / 60_000) % 60)}:${pad(Math.floor(ms / 1000) % 60)},${pad(ms % 1000, 3)}`;
};

let startFrame = 0;
const srt = [];
const missingShots = [];
const generatedScenes = scenes.map((scene) => {
  const sidecarPath = path.join(audioDir, `${scene.id}.json`);
  const wavPath = path.join(audioDir, `${scene.id}.wav`);
  if (!fs.existsSync(sidecarPath) || !fs.existsSync(wavPath)) fail(`Narration is missing for ${scene.id}: run \`npm run audio\`.`);
  const sidecar = JSON.parse(fs.readFileSync(sidecarPath, 'utf8'));
  const durationFrames = Math.max(
    Math.round(scene.targetSeconds * fps),
    narrationLeadFrames + Math.ceil(sidecar.durationMs / 1000 * fps) + sceneTailFrames,
  );
  const leadMs = narrationLeadFrames / fps * 1000;
  // Each caption stays up until the next sentence starts (or the scene ends).
  const captionCues = sidecar.cues.map((cue, index) => ({
    text: cue.text,
    startMs: leadMs + cue.startMs,
    endMs: index + 1 < sidecar.cues.length
      ? leadMs + sidecar.cues[index + 1].startMs
      : Math.min(durationFrames / fps * 1000 - 300, leadMs + cue.endMs + 1200),
  }));
  const sceneStartMs = startFrame / fps * 1000;
  for (const cue of captionCues) {
    srt.push(String(srt.length / 4 + 1), `${srtTime(sceneStartMs + cue.startMs)} --> ${srtTime(sceneStartMs + cue.endMs)}`, cue.text, '');
  }
  fs.copyFileSync(wavPath, path.join(publicGenerated, 'audio', `${scene.id}.wav`));
  const newAssets = scene.newShot ? newAssetsFor(scene.newShot) : [];
  if (scene.newShot && newAssets.length === 0) missingShots.push(scene.newShot);
  const result = {
    id: scene.id,
    startFrame,
    durationFrames,
    audio: `generated/audio/${scene.id}.wav`,
    audioDelayFrames: narrationLeadFrames,
    captionCues,
    newAssets: newAssets.map(({type, src, width, height}) => ({type, src, width, height})),
    newSources: newAssets.map(({source}) => source),
  };
  startFrame += durationFrames;
  return result;
});

const generated = {fps, totalFrames: startFrame, scenes: generatedScenes};
fs.writeFileSync(path.join(videoRoot, 'src', 'generated.ts'),
  `// Generated by scripts/prepare-assets.mjs. Do not edit.\nexport const GENERATED = ${JSON.stringify(generated, null, 2)} as const;\n`);
fs.writeFileSync(path.join(outDir, 'captions.srt'), srt.join('\n'));
fs.writeFileSync(path.join(outDir, 'timeline.json'), JSON.stringify(generatedScenes.map(({id, startFrame: start, durationFrames}) => ({id, start, durationFrames})), null, 2));

const seconds = startFrame / fps;
console.log(`Old app: ${oldFiles.length} screenshots; solid redactions on #17, #18 (email) and #23 (password) only.`);
console.log(`New app: ${byShot.size} shot groups found in ${newDir}.`);
if (missingShots.length > 0) console.log(`Placeholders for shots: ${missingShots.join(', ')}`);
console.log(`Timeline: ${startFrame} frames = ${Math.floor(seconds / 60)}:${String(Math.round(seconds % 60)).padStart(2, '0')} at ${fps} fps.`);
