import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { Avatar, Style } from '@dicebear/core';
import definition from '@dicebear/styles/open-peeps.json' with { type: 'json' };

const here = dirname(fileURLToPath(import.meta.url));
const output = resolve(here, '../../assets/avatars');
const seeds = [
  'alder',
  'brook',
  'coral',
  'delta',
  'estuary',
  'fern',
  'grove',
  'harbour',
  'iris',
  'juniper',
  'kelp',
  'lagoon',
];

await mkdir(output, { recursive: true });
const style = new Style(definition);
for (const [index, seed] of seeds.entries()) {
  const avatar = new Avatar(style, {
    seed,
    borderRadius: [50],
  });
  const filename = `avatar-${String(index + 1).padStart(2, '0')}.svg`;
  await writeFile(resolve(output, filename), avatar.toString(), 'utf8');
}
