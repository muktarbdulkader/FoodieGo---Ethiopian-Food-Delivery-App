#!/usr/bin/env node
/**
 * Generate simple test notification sounds for FoodieGo app.
 * 
 * This script generates basic beep sounds that can be used for testing
 * the notification sound feature. For production, use professional sound files.
 * 
 * Requirements:
 *     npm install node-wav
 * 
 * Usage:
 *     node generate_test_sounds.js
 *     
 * This will create:
 *     - assets/sounds/notification.mp3 (800 Hz beep, 0.5 seconds)
 *     - assets/sounds/bell.mp3 (1200 Hz + 800 Hz bell-like sound, 0.8 seconds)
 */

const fs = require('fs');
const path = require('path');

// Simple WAV file generator (no external dependencies needed)
class WavGenerator {
  constructor(sampleRate = 44100) {
    this.sampleRate = sampleRate;
  }

  generateSineWave(frequency, duration, volume = 0.3) {
    const samples = Math.floor(this.sampleRate * duration);
    const buffer = Buffer.alloc(samples * 2); // 16-bit samples
    
    for (let i = 0; i < samples; i++) {
      const t = i / this.sampleRate;
      const value = Math.sin(2 * Math.PI * frequency * t) * volume;
      const sample = Math.floor(value * 32767);
      buffer.writeInt16LE(sample, i * 2);
    }
    
    return buffer;
  }

  mixBuffers(buffer1, buffer2) {
    const length = Math.min(buffer1.length, buffer2.length);
    const mixed = Buffer.alloc(length);
    
    for (let i = 0; i < length; i += 2) {
      const sample1 = buffer1.readInt16LE(i);
      const sample2 = buffer2.readInt16LE(i);
      const mixedSample = Math.floor((sample1 + sample2) / 2);
      mixed.writeInt16LE(mixedSample, i);
    }
    
    return mixed;
  }

  applyFadeOut(buffer, fadeDuration) {
    const fadeStart = buffer.length - Math.floor(fadeDuration * this.sampleRate * 2);
    
    for (let i = fadeStart; i < buffer.length; i += 2) {
      const sample = buffer.readInt16LE(i);
      const fadeProgress = (i - fadeStart) / (buffer.length - fadeStart);
      const fadedSample = Math.floor(sample * (1 - fadeProgress));
      buffer.writeInt16LE(fadedSample, i);
    }
    
    return buffer;
  }

  createWavFile(audioBuffer) {
    const dataSize = audioBuffer.length;
    const header = Buffer.alloc(44);
    
    // RIFF header
    header.write('RIFF', 0);
    header.writeUInt32LE(36 + dataSize, 4);
    header.write('WAVE', 8);
    
    // fmt chunk
    header.write('fmt ', 12);
    header.writeUInt32LE(16, 16); // fmt chunk size
    header.writeUInt16LE(1, 20); // PCM format
    header.writeUInt16LE(1, 22); // Mono
    header.writeUInt32LE(this.sampleRate, 24);
    header.writeUInt32LE(this.sampleRate * 2, 28); // Byte rate
    header.writeUInt16LE(2, 32); // Block align
    header.writeUInt16LE(16, 34); // Bits per sample
    
    // data chunk
    header.write('data', 36);
    header.writeUInt32LE(dataSize, 40);
    
    return Buffer.concat([header, audioBuffer]);
  }
}

function createDirectory() {
  const dir = path.join(__dirname, 'assets', 'sounds');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  console.log('✓ Created assets/sounds directory');
}

function generateNotificationSound() {
  console.log('Generating notification.mp3...');
  
  const generator = new WavGenerator();
  const audioBuffer = generator.generateSineWave(800, 0.5, 0.3);
  const wavFile = generator.createWavFile(audioBuffer);
  
  const outputPath = path.join(__dirname, 'assets', 'sounds', 'notification.wav');
  fs.writeFileSync(outputPath, wavFile);
  
  console.log(`✓ Generated ${outputPath}`);
  console.log('  Note: Generated as WAV. For MP3, use ffmpeg or download from freesound.org');
}

function generateBellSound() {
  console.log('Generating bell.mp3...');
  
  const generator = new WavGenerator();
  const highTone = generator.generateSineWave(1200, 0.8, 0.2);
  const lowTone = generator.generateSineWave(800, 0.8, 0.2);
  const mixed = generator.mixBuffers(highTone, lowTone);
  const faded = generator.applyFadeOut(mixed, 0.6);
  const wavFile = generator.createWavFile(faded);
  
  const outputPath = path.join(__dirname, 'assets', 'sounds', 'bell.wav');
  fs.writeFileSync(outputPath, wavFile);
  
  console.log(`✓ Generated ${outputPath}`);
  console.log('  Note: Generated as WAV. For MP3, use ffmpeg or download from freesound.org');
}

function convertToMp3() {
  console.log('\nTo convert WAV to MP3, run:');
  console.log('  ffmpeg -i assets/sounds/notification.wav assets/sounds/notification.mp3');
  console.log('  ffmpeg -i assets/sounds/bell.wav assets/sounds/bell.mp3');
  console.log('\nOr update pubspec.yaml to use .wav files instead of .mp3');
}

function main() {
  console.log('Generating test notification sounds...');
  console.log('='.repeat(50));
  
  try {
    createDirectory();
    generateNotificationSound();
    generateBellSound();
    
    console.log('='.repeat(50));
    console.log('✓ All sounds generated successfully!');
    
    console.log('\nOption 1: Convert to MP3 (recommended)');
    convertToMp3();
    
    console.log('\nOption 2: Use WAV files');
    console.log('  Update pubspec.yaml:');
    console.log('    - assets/sounds/notification.wav');
    console.log('    - assets/sounds/bell.wav');
    console.log('  Update code to use .wav extension');
    
    console.log('\nOption 3: Download professional sounds');
    console.log('  - https://freesound.org/');
    console.log('  - https://mixkit.co/free-sound-effects/');
    
    console.log('\nNext steps:');
    console.log('1. Run: flutter pub get');
    console.log('2. Run: flutter run');
    console.log('3. Test the sounds in Kitchen Orders page');
    
  } catch (error) {
    console.error('\n✗ Error generating sounds:', error.message);
    console.log('\nAlternative: Download free sounds from:');
    console.log('  - https://freesound.org/');
    console.log('  - https://mixkit.co/free-sound-effects/');
  }
}

if (require.main === module) {
  main();
}

module.exports = { WavGenerator };
