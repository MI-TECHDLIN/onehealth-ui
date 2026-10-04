# Avatar generator

The app ships 12 static, forward-facing
[DiceBear Avataaars](https://www.dicebear.com/styles/avataaars/) portraits.
Avataaars is artwork by Pablo Stanley, remixed by DiceBear, and is
[free for personal and commercial use](https://avataaars.com/).

Each preset in `generate_avatars.mjs` pins its skin tone, hair or headwear,
eyes, eyebrows, clothing, optional facial hair and glasses, and a brand-token
background. The generator applies the `smile` mouth to every preset. Keep eyes
limited to `happy` or `default` and eyebrows to neutral or excited variants so
every choice remains friendly. Preset filenames and their order are stable
because the app persists `avatar-01` through `avatar-12`.

Regenerate the committed SVG assets with Node.js:

```sh
cd tool/avatar_generator
npm ci
npm run generate
```

Review all 12 portraits after regeneration for a centred, forward-facing pose,
an upbeat expression, and diversity across skin tone, hair, hijab, turban,
facial hair, glasses, and clothing. The SVG metadata embeds the required
licence attribution.
