// Ripple, ported from the vector renders in the OneAquaHealth design board
// (data/oah-design-preview), which mirror the app's 17-parameter
// CustomPainter moods in lib/core/mascot/aqua_mascot.dart. Motion is driven
// by the Remotion frame so renders are deterministic.
import React, {useId} from 'react';
import {useCurrentFrame, useVideoConfig} from 'remotion';

type Mood = {
  body: string; hi: string; tilt: number; ws: number; hs: number; lf: number; rf: number;
  eye: number; pupil: number; smile: number; open: number; brow: number; spark: number;
};

const MOODS = {
  idle: {body: '#2E9EB0', hi: '#A9E0E4', tilt: 0, ws: 1, hs: 1, lf: 0.1, rf: 0.1, eye: 1, pupil: 0, smile: 0.55, open: 0, brow: 0, spark: 0},
  guiding: {body: '#126B78', hi: '#2E9EB0', tilt: 0.08, ws: 0.98, hs: 1.02, lf: 0.2, rf: 1, eye: 1, pupil: 0.22, smile: 0.65, open: 0.15, brow: 0, spark: 0},
  celebrating: {body: '#2E9EB0', hi: '#A9E0E4', tilt: 0, ws: 1.06, hs: 0.96, lf: 1, rf: 1, eye: 0.08, pupil: 0, smile: 1, open: 1, brow: 0, spark: 1},
} satisfies Record<string, Mood>;

export type RippleMood = keyof typeof MOODS;

const RAD = 57.2958;

export const Ripple: React.FC<{size: number; mood?: RippleMood; wave?: boolean; talking?: boolean}> = ({
  size,
  mood = 'guiding',
  wave = false,
  talking = false,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const uid = useId().replace(/:/g, '');
  const s: Mood = MOODS[mood];
  const t = frame / fps;
  const deg = s.tilt * RAD;
  const left = -1 * (0.12 - s.lf * 1.22) * RAD;
  const right = (0.12 - s.rf * 1.22) * RAD;
  // Design-board gestures: the wave replaces the fin pose and swings -8deg..-48deg
  // (slowed from 0.7 s to 0.9 s for video); ambient bob 2.4 s.
  const waveDeg = -28 - 20 * Math.cos((t / 0.9) * 2 * Math.PI);
  const bob = -5 * Math.sin((t / 2.4) * 2 * Math.PI) ** 2;
  const eh = 15 * Math.max(0.1, s.eye);
  const my = 153 + s.smile * 14;
  const openAmount = talking ? 0.35 + 0.3 * Math.abs(Math.sin(t * 9)) : s.open;
  const showOpen = talking || (s.open - 0.28) / 0.3 > 0;
  const mouthH = 9 + 23 * openAmount;
  return (
    <svg width={size} height={size * 1.16} viewBox="0 0 200 232" role="img" aria-label="Ripple">
      <defs>
        <linearGradient id={`body-${uid}`} x1=".16" y1=".05" x2=".84" y2=".95">
          <stop stopColor="#DDF6F6" />
          <stop offset=".28" stopColor={s.hi} />
          <stop offset=".78" stopColor={s.body} />
          <stop offset="1" stopColor="#126B78" />
        </linearGradient>
        <linearGradient id={`fin-${uid}`} x1="0" y1="0" x2="1" y2="1">
          <stop stopColor="#DDEBDD" />
          <stop offset="1" stopColor="#78A98A" />
        </linearGradient>
        <filter id={`shadow-${uid}`} x="-.3" y="-.3" width="1.6" height="1.7">
          <feDropShadow dx="0" dy="5" stdDeviation="4" floodColor="#123047" floodOpacity=".2" />
        </filter>
      </defs>
      <ellipse cx="100" cy="218" rx="48" ry="8" fill="#123047" opacity=".13" />
      <g transform={`translate(0 ${bob})`}>
        <g transform={`rotate(${deg} 100 116) scale(${s.ws} ${s.hs})`}>
          <g transform={`rotate(${left} 49 137)`}>
            <path d="M49 137C34 119 9 119 1 139c18 15 36 14 48-2Z" fill={`url(#fin-${uid})`} stroke="#126B78" strokeWidth="3" />
            <path d="M41 138Q24 135 10 138" fill="none" stroke="#F8FCFB" strokeOpacity=".72" strokeWidth="2.5" />
          </g>
          <g transform={`rotate(${wave ? waveDeg : right} 151 137)`}>
            <path d="M151,137c15,-18 40,-18 48,2 -18,15 -36,14 -48,-2Z" fill={`url(#fin-${uid})`} stroke="#126B78" strokeWidth="3" />
            <path d="M159 138q17-3 31 0" fill="none" stroke="#F8FCFB" strokeOpacity=".72" strokeWidth="2.5" />
          </g>
          <path
            d="M100 16C91 43 42 74 42 132c0 46 25 75 58 75 37 0 58-29 58-75 0-57-47-89-58-116Z"
            fill={`url(#body-${uid})`}
            stroke="#126B78"
            strokeWidth="4"
            strokeLinejoin="round"
            filter={`url(#shadow-${uid})`}
          />
          <ellipse cx="105" cy="166" rx="36" ry="28" fill="#F8FCFB" opacity=".12" />
          <path d="M77 53C60 75 54 101 55 122" fill="none" stroke="#fff" strokeOpacity=".55" strokeWidth="8" strokeLinecap="round" />
          <path d="M69 87c7-12 13-17 18-21" fill="none" stroke="#fff" strokeOpacity=".24" strokeWidth="3" strokeLinecap="round" />
          <ellipse cx="78" cy="124" rx="8.5" ry={eh / 2} fill="#F8FCFB" stroke="#123047" strokeWidth="2.5" />
          <ellipse cx="122" cy="124" rx="8.5" ry={eh / 2} fill="#F8FCFB" stroke="#123047" strokeWidth="2.5" />
          <ellipse cx={79 + s.pupil * 6} cy="126" rx="4.2" ry={Math.max(1.4, eh / 3)} fill="#123047" />
          <ellipse cx={123 + s.pupil * 6} cy="126" rx="4.2" ry={Math.max(1.4, eh / 3)} fill="#123047" />
          {s.eye > 0.35 && (
            <>
              <circle cx={77 + s.pupil * 6} cy="122" r="1.6" fill="#fff" />
              <circle cx={121 + s.pupil * 6} cy="122" r="1.6" fill="#fff" />
            </>
          )}
          {s.smile > 0.2 && (
            <g fill="#F5B69B" opacity=".45">
              <ellipse cx="67" cy="147" rx="8" ry="4" />
              <ellipse cx="133" cy="147" rx="8" ry="4" />
            </g>
          )}
          {showOpen ? (
            <g>
              <rect x="79" y={158 - mouthH / 2} width="42" height={mouthH} rx="17" fill="#123047" />
              <path d="M87 164q13 10 26 0" fill="#F5B69B" />
            </g>
          ) : (
            <path d={`M84 153Q100 ${my} 116 153`} fill="none" stroke="#123047" strokeWidth="4.5" strokeLinecap="round" />
          )}
        </g>
        {s.spark > 0 && (
          <g fill="#FFE6AB">
            <path d="m25 51 3 6 6 3-6 3-3 6-3-6-6-3 6-3Z" />
            <path d="m174 39 3 6 6 3-6 3-3 6-3-6-6-3 6-3Z" />
            <path d="m184 116 3 6 6 3-6 3-3 6-3-6-6-3 6-3Z" />
          </g>
        )}
      </g>
    </svg>
  );
};
