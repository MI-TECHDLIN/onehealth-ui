import React from 'react';
import {Composition} from 'remotion';
import {OneHealthDemo} from './Video';
import {GENERATED} from './generated';

export const VideoRoot: React.FC = () => (
  <Composition
    id="OneHealthDemo"
    component={OneHealthDemo}
    durationInFrames={GENERATED.totalFrames}
    fps={GENERATED.fps}
    width={1920}
    height={1080}
  />
);

