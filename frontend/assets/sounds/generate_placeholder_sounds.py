#!/usr/bin/env python3
"""
Generate placeholder notification sounds for FoodieGo Kitchen Dashboard.

This script creates simple beep sounds as placeholders for language-specific
notifications. Replace these with proper text-to-speech generated audio.

Requirements:
    pip install pydub

Usage:
    python generate_placeholder_sounds.py
"""

import os
from pydub import AudioSegment
from pydub.generators import Sine

def generate_beep(filename, frequency=800, duration_ms=1000, volume=-10):
    """
    Generate a simple beep sound.
    
    Args:
        filename: Output filename
        frequency: Tone frequency in Hz (default 800)
        duration_ms: Duration in milliseconds (default 1000)
        volume: Volume in dB (default -10)
    """
    # Generate sine wave
    sine_wave = Sine(frequency)
    
    # Create audio segment
    audio = sine_wave.to_audio_segment(
        duration=duration_ms,
        volume=volume
    )
    
    # Add fade in/out for smoother sound
    audio = audio.fade_in(50).fade_out(100)
    
    # Export as MP3
    audio.export(filename, format="mp3", bitrate="128k")
    print(f"Generated: {filename}")

def generate_double_beep(filename, frequency=600, duration_ms=500):
    """Generate two quick beeps for attention."""
    beep1 = Sine(frequency).to_audio_segment(duration=duration_ms, volume=-10)
    beep1 = beep1.fade_in(50).fade_out(50)
    
    silence = AudioSegment.silent(duration=200)
    
    beep2 = Sine(frequency).to_audio_segment(duration=duration_ms, volume=-10)
    beep2 = beep2.fade_in(50).fade_out(100)
    
    audio = beep1 + silence + beep2
    audio.export(filename, format="mp3", bitrate="128k")
    print(f"Generated: {filename}")

def generate_ascending_tone(filename, start_freq=400, end_freq=800, duration_ms=800):
    """Generate an ascending tone for positive notifications."""
    # Create a simple sweep effect
    audio = AudioSegment.silent(duration=0)
    steps = 10
    step_duration = duration_ms // steps
    
    for i in range(steps):
        freq = start_freq + ((end_freq - start_freq) * i // steps)
        tone = Sine(freq).to_audio_segment(duration=step_duration, volume=-10)
        audio += tone
    
    audio = audio.fade_out(100)
    audio.export(filename, format="mp3", bitrate="128k")
    print(f"Generated: {filename}")

def generate_descending_tone(filename, start_freq=800, end_freq=400, duration_ms=800):
    """Generate a descending tone."""
    audio = AudioSegment.silent(duration=0)
    steps = 10
    step_duration = duration_ms // steps
    
    for i in range(steps):
        freq = start_freq - ((start_freq - end_freq) * i // steps)
        tone = Sine(freq).to_audio_segment(duration=step_duration, volume=-10)
        audio += tone
    
    audio = audio.fade_out(100)
    audio.export(filename, format="mp3", bitrate="128k")
    print(f"Generated: {filename}")

def main():
    """Generate all placeholder sound files."""
    print("=" * 60)
    print("FoodieGo Kitchen Dashboard - Sound Generator")
    print("=" * 60)
    print()
    
    # Check if pydub is installed
    try:
        from pydub import AudioSegment
    except ImportError:
        print("ERROR: pydub is not installed!")
        print("Please install it: pip install pydub")
        print()
        print("Also requires ffmpeg:")
        print("  - Windows: download from https://ffmpeg.org/download.html")
        print("  - macOS: brew install ffmpeg")
        print("  - Linux: sudo apt-get install ffmpeg")
        return
    
    print("Generating placeholder notification sounds...")
    print("NOTE: Replace these with proper text-to-speech audio!")
    print()
    
    # Generate generic sounds
    print("[Generic Sounds]")
    generate_beep("notification.mp3", frequency=880, duration_ms=600)
    generate_double_beep("bell.mp3", frequency=700, duration_ms=400)
    print()
    
    # Generate English placeholders (distinctive tones)
    print("[English Placeholders]")
    generate_ascending_tone("waiter_call_en.mp3", start_freq=600, end_freq=900, duration_ms=800)
    generate_ascending_tone("new_order_en.mp3", start_freq=500, end_freq=800, duration_ms=600)
    generate_ascending_tone("order_ready_en.mp3", start_freq=700, end_freq=1000, duration_ms=700)
    print()
    
    # Generate Amharic placeholders (different frequency range)
    print("[Amharic Placeholders]")
    generate_beep("waiter_call_am.mp3", frequency=650, duration_ms=900, volume=-8)
    generate_double_beep("new_order_am.mp3", frequency=550, duration_ms=450)
    generate_descending_tone("order_ready_am.mp3", start_freq=850, end_freq=550, duration_ms=700)
    print()
    
    # Generate Oromo placeholders (different patterns)
    print("[Oromo Placeholders]")
    generate_beep("waiter_call_om.mp3", frequency=750, duration_ms=850, volume=-8)
    generate_double_beep("new_order_om.mp3", frequency=620, duration_ms=400)
    generate_ascending_tone("order_ready_om.mp3", start_freq=620, end_freq=920, duration_ms=750)
    print()
    
    print("=" * 60)
    print("All placeholder sounds generated successfully!")
    print()
    print("NEXT STEPS:")
    print("1. Run: flutter pub get")
    print("2. Test sounds in Kitchen Dashboard")
    print("3. Replace placeholders with real TTS audio:")
    print("   - Google Cloud Text-to-Speech")
    print("   - Amazon Polly")
    print("   - Azure Speech Services")
    print("   - Or record native speakers")
    print("=" * 60)

if __name__ == "__main__":
    main()
