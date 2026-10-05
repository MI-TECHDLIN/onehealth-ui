import '@fontsource/baloo-2/600.css';
import '@fontsource/baloo-2/700.css';
import '@fontsource/noto-sans/400.css';
import '@fontsource/noto-sans/600.css';
import '@fontsource/noto-sans/700.css';

import {
  ArrowRightIcon,
  BellIcon,
  BuildingsIcon,
  ChartLineUpIcon,
  DeviceMobileIcon,
  DropIcon,
  FishIcon,
  FootprintsIcon,
  GithubLogoIcon,
  PawPrintIcon,
  PlantIcon,
  SpeakerHighIcon,
  TranslateIcon,
  UsersThreeIcon,
} from '@phosphor-icons/react';
import React, {useEffect, useState} from 'react';
import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  OffthreadVideo,
  Sequence,
  continueRender,
  delayRender,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {GENERATED} from './generated';
import {Ripple} from './Ripple';
import sceneSource from './scenes.json';

// Brand tokens from lib/core/theme/tokens.dart (see the design report).
const c = {
  navy: '#123047',
  deepWater: '#126B78',
  water: '#2E9EB0',
  waterLight: '#A9E0E4',
  waterMist: '#E9F7F7',
  foam: '#F8FCFB',
  ink: '#173242',
  muted: '#506773',
  outline: '#B7C9CC',
  sage: '#78A98A',
  sageLight: '#DDEBDD',
  peach: '#F5B69B',
  peachLight: '#FFE8DC',
  sparkle: '#FFE6AB',
  white: '#FFFFFF',
};
const display = '"Baloo 2", "Noto Sans", sans-serif';
const body = '"Noto Sans", sans-serif';
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const ease = Easing.bezier(0.4, 0, 0.2, 1);

// Phone frame geometry: ~80% of the 1080 px frame height, old screenshots are 720x1604.
const PHONE_H = 860;
const PHONE_PAD = 12;
const SCREEN_H = PHONE_H - PHONE_PAD * 2;
const SCREEN_W = Math.round((SCREEN_H * 720) / 1604);
const PHONE_W = SCREEN_W + PHONE_PAD * 2;
const PHONE_TOP = 18;
const PHONE_GAP = 150;
const LEFT_X = 960 - PHONE_GAP / 2 - PHONE_W;
const RIGHT_X = 960 + PHONE_GAP / 2;

type Asset = {type: 'image' | 'video'; src: string; width?: number; height?: number};
type Cue = {text: string; startMs: number; endMs: number};
type Zoom = {index?: number; x: number; y: number; scale: number};
type Scene = {
  id: string;
  kind: 'intro' | 'about' | 'compare' | 'closing' | 'end';
  targetSeconds: number;
  captionText: string;
  piperText: string;
  title?: string;
  visual?: 'streams' | 'oneHealth' | 'citizens' | 'rebuilt';
  now?: string[];
  oldShots?: number[];
  oldEmpty?: string;
  improvement?: string;
  beforeFact?: string;
  nowFact?: string;
  wipe?: {old: number; now: number};
  zoom?: Zoom;
};
type Generated = {
  id: string;
  startFrame: number;
  durationFrames: number;
  audio: string;
  audioDelayFrames: number;
  captionCues: readonly Cue[];
  newAssets: readonly Asset[];
};

const scenes = sceneSource as Scene[];
const oldAsset = (shot: number): Asset => ({type: 'image', src: `generated/old/old-${String(shot).padStart(2, '0')}.png`, width: 720, height: 1604});

const useFonts = () => {
  const [handle] = useState(() => delayRender('Loading Baloo 2 and Noto Sans'));
  useEffect(() => {
    Promise.all([
      document.fonts.load('700 40px "Baloo 2"'),
      document.fonts.load('600 40px "Baloo 2"'),
      document.fonts.load('400 30px "Noto Sans"'),
      document.fonts.load('600 30px "Noto Sans"'),
      document.fonts.load('700 30px "Noto Sans"'),
    ]).then(() => continueRender(handle));
  }, [handle]);
};

export const OneHealthDemo: React.FC = () => {
  useFonts();
  return (
    <AbsoluteFill style={{backgroundColor: c.white, fontFamily: body, color: c.ink}}>
      {scenes.map((scene) => {
        const generated = GENERATED.scenes.find((item) => item.id === scene.id) as Generated | undefined;
        if (!generated) throw new Error(`Scene ${scene.id} is not prepared: run npm run assets`);
        return (
          <Sequence key={scene.id} name={scene.id} from={generated.startFrame} durationInFrames={generated.durationFrames}>
            <SceneView scene={scene} generated={generated} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const SceneView: React.FC<{scene: Scene; generated: Generated}> = ({scene, generated}) => {
  const frame = useCurrentFrame();
  const d = generated.durationFrames;
  const opacity = interpolate(frame, [0, 10, d - 10, d], [0, 1, 1, 0], clamp);
  return (
    <AbsoluteFill style={{backgroundColor: c.white}}>
      <Sequence from={generated.audioDelayFrames} layout="none">
        <Audio src={staticFile(generated.audio)} />
      </Sequence>
      <AbsoluteFill style={{opacity}}>
        {scene.kind === 'intro' && <Intro />}
        {scene.kind === 'about' && <About scene={scene} />}
        {scene.kind === 'compare' && <Compare scene={scene} generated={generated} />}
        {scene.kind === 'closing' && <Closing scene={scene} />}
        {scene.kind === 'end' && <EndCard />}
        <Caption cues={generated.captionCues} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/* ---------- Intro and end cards (the only places the logo appears) ---------- */

const Logo: React.FC<{width: number}> = ({width}) => (
  <Img src={staticFile('generated/oneaquahealth-logo.svg')} style={{width, height: 'auto', display: 'block'}} />
);

const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const logoIn = interpolate(frame, [0, 28], [0, 1], {...clamp, easing: ease});
  const rippleIn = interpolate(frame, [30, 58], [0, 1], {...clamp, easing: ease});
  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', paddingBottom: 120}}>
      <div style={{opacity: logoIn, transform: `translateY(${(1 - logoIn) * 24}px)`}}>
        <Logo width={1000} />
      </div>
      <div style={{marginTop: 46, opacity: rippleIn, transform: `translateY(${(1 - rippleIn) * 40}px)`}}>
        <Ripple size={230} mood="guiding" wave />
      </div>
    </AbsoluteFill>
  );
};

const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const appear = interpolate(frame, [0, 24], [0, 1], {...clamp, easing: ease});
  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', paddingBottom: 150, opacity: appear}}>
      <Logo width={860} />
      <div style={{display: 'flex', alignItems: 'center', gap: 56, marginTop: 40}}>
        <Ripple size={170} mood="guiding" wave />
        <div>
          <div style={{fontFamily: display, fontWeight: 700, fontSize: 52, color: c.navy, lineHeight: 1.1}}>
            Citizen science for healthier city streams
          </div>
          <div style={{display: 'flex', alignItems: 'center', gap: 14, marginTop: 18, fontSize: 34, fontWeight: 600, color: c.deepWater}}>
            <GithubLogoIcon size={40} weight="fill" /> github.com/MI-TECHDLIN/onehealth-ui
          </div>
        </div>
      </div>
      <div style={{position: 'absolute', bottom: 112, fontSize: 20, color: c.muted, textAlign: 'center', lineHeight: 1.5}}>
        Voice: Piper en_GB-alba-medium (CC BY 4.0) · Map data © OpenStreetMap contributors, tiles by OpenFreeMap
        <br />
        Logo: oneaquahealth.eu · Video made in code with Remotion
      </div>
    </AbsoluteFill>
  );
};

/* ---------- About OneAquaHealth ---------- */

const Title: React.FC<{text: string}> = ({text}) => {
  const frame = useCurrentFrame();
  const appear = interpolate(frame, [4, 26], [0, 1], {...clamp, easing: ease});
  return (
    <div style={{position: 'absolute', top: 70, left: 0, right: 0, textAlign: 'center', opacity: appear, transform: `translateY(${(1 - appear) * 18}px)`}}>
      <div style={{fontFamily: display, fontWeight: 700, fontSize: 76, color: c.navy, lineHeight: 1.1}}>{text}</div>
      <div style={{height: 8, width: 140, borderRadius: 99, backgroundColor: c.water, margin: '14px auto 0'}} />
    </div>
  );
};

// A horizontally centred band of the frame; AbsoluteFill is always full height.
const stage: React.CSSProperties = {position: 'absolute', left: 0, right: 0, display: 'flex', alignItems: 'center', justifyContent: 'center'};

const Stagger: React.FC<{index: number; children: React.ReactNode; start?: number}> = ({index, children, start = 18}) => {
  const frame = useCurrentFrame();
  const appear = interpolate(frame, [start + index * 14, start + index * 14 + 20], [0, 1], {...clamp, easing: ease});
  return <div style={{opacity: appear, transform: `translateY(${(1 - appear) * 30}px)`}}>{children}</div>;
};

const IconTile: React.FC<{icon: React.ReactNode; label: string; tint: string; size?: number}> = ({icon, label, tint, size = 300}) => (
  <div style={{width: size, height: size, borderRadius: 48, backgroundColor: tint, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14, color: c.deepWater}}>
    {icon}
    <div style={{fontFamily: display, fontWeight: 700, fontSize: 40, color: c.navy}}>{label}</div>
  </div>
);

const About: React.FC<{scene: Scene}> = ({scene}) => (
  <AbsoluteFill>
    <Title text={scene.title ?? ''} />
    <div style={{...stage, top: 215, height: 700}}>
      {scene.visual === 'streams' && <StreamsVisual />}
      {scene.visual === 'oneHealth' && <OneHealthVisual />}
      {scene.visual === 'citizens' && <CitizensVisual />}
      {scene.visual === 'rebuilt' && <RebuiltVisual />}
    </div>
  </AbsoluteFill>
);

const StreamsVisual: React.FC = () => {
  const frame = useCurrentFrame();
  const flow = (frame * 1.6) % 120;
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 70}}>
      <svg width="600" height="540" viewBox="0 0 620 560">
        <rect x="0" y="0" width="620" height="560" rx="48" fill={c.waterMist} />
        {[40, 130, 450, 520].map((x, i) => (
          <rect key={x} x={x} y={[90, 150, 70, 170][i]} width="62" height={[300, 240, 320, 220][i]} rx="10" fill={c.outline} />
        ))}
        <path d="M250 0 C 190 140, 380 220, 300 330 S 260 480, 360 560" stroke={c.water} strokeWidth="78" fill="none" strokeLinecap="round" />
        <path d="M250 0 C 190 140, 380 220, 300 330 S 260 480, 360 560" stroke={c.waterLight} strokeWidth="10" fill="none" strokeDasharray="40 80" strokeDashoffset={-flow} strokeLinecap="round" />
        <ellipse cx="200" cy="480" rx="70" ry="34" fill={c.sage} opacity=".8" />
        <ellipse cx="430" cy="40" rx="80" ry="30" fill={c.sage} opacity=".8" />
      </svg>
      <div style={{display: 'flex', flexDirection: 'column', gap: 26}}>
        {[
          [<DropIcon key="d" size={64} weight="fill" />, 'Water', c.waterMist],
          [<FishIcon key="f" size={64} weight="fill" />, 'Wildlife', c.sageLight],
          [<UsersThreeIcon key="u" size={64} weight="fill" />, 'People', c.peachLight],
        ].map(([icon, label, tint], index) => (
          <Stagger key={label as string} index={index}>
            <div style={{display: 'flex', alignItems: 'center', gap: 26, width: 460, padding: '22px 30px', borderRadius: 32, backgroundColor: tint as string, color: c.deepWater}}>
              {icon}
              <div style={{fontFamily: display, fontWeight: 700, fontSize: 48, color: c.navy}}>{label}</div>
            </div>
          </Stagger>
        ))}
      </div>
    </div>
  );
};

const OneHealthVisual: React.FC = () => {
  const frame = useCurrentFrame();
  const join = interpolate(frame, [20, 80], [70, 0], {...clamp, easing: ease});
  const circles: Array<[string, string, React.ReactNode, number, number]> = [
    ['Ecosystem', c.sageLight, <PlantIcon key="p" size={70} weight="fill" />, 330, 210],
    ['Animal', c.sparkle, <PawPrintIcon key="a" size={70} weight="fill" />, 590, 210],
    ['Human', c.peachLight, <UsersThreeIcon key="h" size={70} weight="fill" />, 460, 430],
  ];
  return (
    <div style={{position: 'relative', width: 920, height: 660}}>
      {circles.map(([label, tint, icon, x, y]) => {
        const dx = (x - 460) / 130;
        const dy = (y - 283) / 147;
        return (
          <div key={label} style={{position: 'absolute', left: x - 185 + dx * join, top: y - 185 + dy * join, width: 370, height: 370, borderRadius: '50%', backgroundColor: tint, opacity: 0.92, border: `4px solid ${c.white}`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: c.deepWater, mixBlendMode: 'multiply'}}>
            <div style={{transform: `translate(${dx * 70}px, ${dy * 60}px)`, display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
              {icon}
              <div style={{fontFamily: display, fontWeight: 700, fontSize: 40, color: c.navy}}>{label}</div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

const CitizensVisual: React.FC = () => {
  const steps: Array<[React.ReactNode, string, string]> = [
    [<DeviceMobileIcon key="m" size={84} weight="fill" />, 'A citizen checks a stream', c.waterMist],
    [<ChartLineUpIcon key="c" size={84} weight="fill" />, 'Data reaches researchers', c.sageLight],
    [<BellIcon key="b" size={84} weight="fill" />, 'Supports early warning', c.peachLight],
  ];
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 34}}>
      {steps.map(([icon, label, tint], index) => (
        <React.Fragment key={label}>
          {index > 0 && (
            <Stagger index={index * 2 - 1} start={20}>
              <ArrowRightIcon size={64} color={c.water} weight="bold" />
            </Stagger>
          )}
          <Stagger index={index * 2} start={20}>
            <div style={{width: 420, height: 380, borderRadius: 48, backgroundColor: tint, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 24, color: c.deepWater, textAlign: 'center', padding: 30, boxSizing: 'border-box'}}>
              {icon}
              <div style={{fontFamily: display, fontWeight: 700, fontSize: 42, color: c.navy, lineHeight: 1.15}}>{label}</div>
            </div>
          </Stagger>
        </React.Fragment>
      ))}
    </div>
  );
};

const RebuiltVisual: React.FC = () => {
  const frame = useCurrentFrame();
  const shift = interpolate(frame, [100, 150], [0, 1], {...clamp, easing: ease});
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 90}}>
      <div style={{textAlign: 'center', opacity: 1 - shift * 0.45, filter: `grayscale(${shift})`}}>
        <SmallPhone asset={oldAsset(10)} height={600} />
        <div style={{marginTop: 18, fontSize: 30, fontWeight: 600, color: c.muted}}>A form built for scientists</div>
      </div>
      <div style={{opacity: shift}}>
        <ArrowRightIcon size={80} color={c.water} weight="bold" />
      </div>
      <div style={{textAlign: 'center', opacity: shift, transform: `translateX(${(1 - shift) * 40}px)`}}>
        <div style={{width: 420, height: 600, borderRadius: 56, backgroundColor: c.waterMist, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 20}}>
          <Ripple size={250} mood="guiding" wave />
          <div style={{display: 'flex', alignItems: 'center', gap: 12, color: c.deepWater}}>
            <BuildingsIcon size={46} weight="fill" />
            <DropIcon size={46} weight="fill" />
            <UsersThreeIcon size={46} weight="fill" />
          </div>
        </div>
        <div style={{marginTop: 18, fontSize: 30, fontWeight: 600, color: c.deepWater}}>Built for the water's edge</div>
      </div>
    </div>
  );
};

/* ---------- Before vs Now ---------- */

const Compare: React.FC<{scene: Scene; generated: Generated}> = ({scene, generated}) => {
  const frame = useCurrentFrame();
  const oldAssets = (scene.oldShots ?? []).map(oldAsset);
  const newAssets = [...generated.newAssets];
  const wipeEnd = scene.wipe ? 165 : 0;
  const pairIn = scene.wipe ? interpolate(frame, [wipeEnd - 15, wipeEnd + 5], [0, 1], clamp) : 1;
  const cycleFrames = generated.durationFrames - wipeEnd;
  const improvementIn = interpolate(frame, [wipeEnd + 6, wipeEnd + 26], [0, 1], {...clamp, easing: ease});
  return (
    <AbsoluteFill>
      {scene.wipe && (
        <AbsoluteFill style={{opacity: 1 - pairIn}}>
          <Wipe oldAsset={oldAsset(scene.wipe.old)} newAsset={newAssets[scene.wipe.now]} />
        </AbsoluteFill>
      )}
      <AbsoluteFill style={{opacity: pairIn}}>
        <Sequence from={wipeEnd} layout="none">
          <Side label="Before" align="right" x={0} width={LEFT_X - 40} accent={c.muted} fact={scene.beforeFact} />
          <Side label="Now" align="left" x={RIGHT_X + PHONE_W + 40} width={1920 - RIGHT_X - PHONE_W - 80} accent={c.deepWater} fact={scene.nowFact} />
          <div style={{position: 'absolute', left: LEFT_X, top: PHONE_TOP}}>
            <Phone muted>
              {oldAssets.length > 0 ? <MediaCycle assets={oldAssets} duration={cycleFrames} /> : <NothingBefore text={scene.oldEmpty ?? 'Nothing before'} />}
            </Phone>
          </div>
          <div style={{position: 'absolute', left: RIGHT_X, top: PHONE_TOP}}>
            <Phone>
              <MediaCycle assets={newAssets} duration={cycleFrames} />
            </Phone>
          </div>
          {scene.zoom && (
            <ZoomCallout zoom={scene.zoom} asset={newAssets[scene.zoom.index ?? 0]} segment={Math.floor(cycleFrames / newAssets.length)} />
          )}
        </Sequence>
        <div style={{position: 'absolute', left: 0, right: 0, top: PHONE_TOP + PHONE_H + 10, textAlign: 'center', opacity: improvementIn, fontFamily: display, fontWeight: 700, fontSize: 46, color: c.navy, lineHeight: 1.1}}>
          {scene.improvement}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Side: React.FC<{label: string; align: 'left' | 'right'; x: number; width: number; accent: string; fact?: string}> = ({label, align, x, width, accent, fact}) => {
  const frame = useCurrentFrame();
  const factIn = interpolate(frame, [40, 60], [0, 1], {...clamp, easing: ease});
  return (
    <div style={{position: 'absolute', left: x, top: PHONE_TOP + 40, width, display: 'flex', flexDirection: 'column', alignItems: align === 'right' ? 'flex-end' : 'flex-start', textAlign: align}}>
      <div style={{fontFamily: display, fontWeight: 700, fontSize: 64, color: accent, lineHeight: 1}}>{label}</div>
      <div style={{height: 7, width: 90, borderRadius: 99, backgroundColor: label === 'Now' ? c.water : c.outline, marginTop: 10}} />
      {fact && (
        <div style={{marginTop: 36, maxWidth: 380, padding: '18px 24px', borderRadius: 24, backgroundColor: label === 'Now' ? c.waterMist : '#F1F4F5', color: label === 'Now' ? c.deepWater : c.muted, fontSize: 28, fontWeight: 600, lineHeight: 1.3, opacity: factIn, transform: `translateY(${(1 - factIn) * 16}px)`}}>
          {fact}
        </div>
      )}
    </div>
  );
};

const Phone: React.FC<{children: React.ReactNode; muted?: boolean}> = ({children, muted}) => (
  <div style={{width: PHONE_W, height: PHONE_H, borderRadius: 52, padding: PHONE_PAD, boxSizing: 'border-box', backgroundColor: muted ? '#5D6F7A' : c.navy, boxShadow: '0 26px 60px rgba(18,48,71,.20)', position: 'relative'}}>
    <div style={{width: SCREEN_W, height: SCREEN_H, borderRadius: 40, overflow: 'hidden', position: 'relative', backgroundColor: c.white}}>{children}</div>
  </div>
);

const SmallPhone: React.FC<{asset: Asset; height: number}> = ({asset, height}) => {
  const screenH = height - 20;
  return (
    <div style={{height, width: Math.round((screenH * 720) / 1604) + 20, borderRadius: 40, padding: 10, boxSizing: 'border-box', backgroundColor: '#5D6F7A'}}>
      <div style={{height: '100%', borderRadius: 31, overflow: 'hidden', backgroundColor: c.white}}>
        <Media asset={asset} />
      </div>
    </div>
  );
};

const Media: React.FC<{asset: Asset}> = ({asset}) => {
  const style: React.CSSProperties = {width: '100%', height: '100%', objectFit: 'contain', objectPosition: 'top center', display: 'block'};
  return asset.type === 'video' ? <OffthreadVideo src={staticFile(asset.src)} muted style={style} /> : <Img src={staticFile(asset.src)} style={style} />;
};

// Shows each asset in turn with a short crossfade.
const MediaCycle: React.FC<{assets: Asset[]; duration: number}> = ({assets, duration}) => {
  const frame = useCurrentFrame();
  const segment = Math.max(1, Math.floor(duration / assets.length));
  return (
    <>
      {assets.map((asset, index) => {
        const start = index * segment;
        const opacity = index === 0 ? interpolate(frame, [segment - 8, segment + 8], [1, assets.length > 1 ? 0 : 1], clamp)
          : interpolate(frame, [start - 8, start + 8, start + segment - 8, start + segment + 8], [0, 1, 1, index === assets.length - 1 ? 1 : 0], clamp);
        if (opacity <= 0) return null;
        return (
          <Sequence key={asset.src} from={asset.type === 'video' ? start - 8 : 0} layout="none">
            <div style={{position: 'absolute', inset: 0, opacity}}>
              <Media asset={asset} />
            </div>
          </Sequence>
        );
      })}
    </>
  );
};

const NothingBefore: React.FC<{text: string}> = ({text}) => (
  <div style={{width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#F1F4F5', color: c.muted, textAlign: 'center', padding: 36, boxSizing: 'border-box'}}>
    <div style={{fontFamily: display, fontWeight: 600, fontSize: 40, lineHeight: 1.15}}>{text}</div>
  </div>
);

const Wipe: React.FC<{oldAsset: Asset; newAsset: Asset}> = ({oldAsset: before, newAsset}) => {
  const frame = useCurrentFrame();
  // Divider position as % from the left: Before on the left, Now on the right.
  const split = interpolate(frame, [14, 70, 120, 140], [88, 12, 50, 50], {...clamp, easing: Easing.inOut(Easing.cubic)});
  const left = 960 - PHONE_W / 2;
  return (
    <AbsoluteFill>
      <Side label="Before" align="right" x={0} width={left - 50} accent={c.muted} />
      <Side label="Now" align="left" x={left + PHONE_W + 50} width={1920 - left - PHONE_W - 100} accent={c.deepWater} />
      <div style={{position: 'absolute', left, top: PHONE_TOP}}>
        <Phone>
          <div style={{position: 'absolute', inset: 0}}>
            <Media asset={before} />
          </div>
          <div style={{position: 'absolute', inset: 0, clipPath: `inset(0 0 0 ${split}%)`}}>
            <Media asset={newAsset} />
          </div>
          <div style={{position: 'absolute', top: 0, bottom: 0, left: `${split}%`, width: 6, marginLeft: -3, backgroundColor: c.white, boxShadow: '0 0 0 2px rgba(18,48,71,.25)'}}>
            <div style={{position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', width: 64, height: 64, borderRadius: '50%', backgroundColor: c.deepWater, border: `4px solid ${c.white}`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: c.white, fontSize: 30, fontWeight: 700}}>
              ‹›
            </div>
          </div>
        </Phone>
      </div>
    </AbsoluteFill>
  );
};

// A gentle magnifier on one detail of the "Now" phone, while "Before" stays visible.
// It shows only while its still is on screen (MediaCycle segment `zoom.index`).
const ZoomCallout: React.FC<{zoom: Zoom; asset: Asset; segment: number}> = ({zoom, asset, segment}) => {
  const frame = useCurrentFrame();
  const start = (zoom.index ?? 0) * segment;
  const appear = interpolate(frame, [start + 45, start + 70, start + segment - 14, start + segment], [0, 1, 1, 0], {...clamp, easing: ease});
  if (appear <= 0) return null;
  const aspect = asset.width && asset.height ? asset.height / asset.width : 1604 / 720;
  // Image is drawn with contain + top alignment in the phone screen.
  const drawnW = Math.min(SCREEN_W, SCREEN_H / aspect);
  const drawnH = drawnW * aspect;
  const offsetX = (SCREEN_W - drawnW) / 2;
  const pointX = RIGHT_X + PHONE_PAD + offsetX + zoom.x * drawnW;
  const pointY = PHONE_TOP + PHONE_PAD + zoom.y * drawnH;
  const diameter = 380;
  const centerX = RIGHT_X + PHONE_W + 40 + diameter / 2;
  const centerY = Math.min(Math.max(pointY, 580), 700); // below the "Now" note
  const zoomW = drawnW * zoom.scale;
  return (
    <AbsoluteFill style={{opacity: appear}}>
      <svg width="1920" height="1080" style={{position: 'absolute', inset: 0}}>
        <circle cx={pointX} cy={pointY} r={46} fill="none" stroke={c.water} strokeWidth={5} />
        <line x1={pointX + 46} y1={pointY} x2={centerX - diameter / 2} y2={centerY} stroke={c.water} strokeWidth={4} />
      </svg>
      <div style={{position: 'absolute', left: centerX - diameter / 2, top: centerY - diameter / 2, width: diameter, height: diameter, borderRadius: '50%', overflow: 'hidden', border: `6px solid ${c.water}`, boxShadow: '0 20px 50px rgba(18,48,71,.25)', backgroundColor: c.white, transform: `scale(${0.85 + 0.15 * appear})`}}>
        {asset.type === 'image' && (
          <Img src={staticFile(asset.src)} style={{position: 'absolute', width: zoomW, height: zoomW * aspect, left: diameter / 2 - zoom.x * zoomW, top: diameter / 2 - zoom.y * zoomW * aspect, maxWidth: 'none'}} />
        )}
      </div>
    </AbsoluteFill>
  );
};

/* ---------- Closing ---------- */

const Closing: React.FC<{scene: Scene}> = ({scene}) => {
  const features: Array<[React.ReactNode, string, string]> = [
    [<TranslateIcon key="t" size={92} weight="fill" />, '18 languages', c.waterMist],
    [<SpeakerHighIcon key="s" size={92} weight="fill" />, 'Reads aloud', c.sageLight],
    [<FootprintsIcon key="f" size={92} weight="fill" />, 'One step at a time', c.peachLight],
  ];
  return (
    <AbsoluteFill>
      <Title text={scene.title ?? ''} />
      <div style={{...stage, top: 250, height: 640, gap: 44}}>
        {features.map(([icon, label, tint], index) => (
          <Stagger key={label} index={index} start={90}>
            <IconTile icon={icon} label={label} tint={tint} size={400} />
          </Stagger>
        ))}
      </div>
    </AbsoluteFill>
  );
};

/* ---------- Burned-in captions ---------- */

const Caption: React.FC<{cues: readonly Cue[]}> = ({cues}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const ms = (frame / fps) * 1000;
  const cue = cues.find((item) => ms >= item.startMs && ms < item.endMs);
  if (!cue) return null;
  const appear = interpolate(ms - cue.startMs, [0, 150], [0, 1], clamp);
  return (
    <div style={{position: 'absolute', left: 0, right: 0, bottom: 16, display: 'flex', justifyContent: 'center', opacity: appear}}>
      <div style={{maxWidth: 1760, padding: '10px 30px', borderRadius: 22, backgroundColor: 'rgba(241,247,247,.97)', border: `2px solid ${c.waterLight}`, color: c.navy, fontSize: 32, fontWeight: 600, lineHeight: 1.3, textAlign: 'center'}}>
        {cue.text}
      </div>
    </div>
  );
};
