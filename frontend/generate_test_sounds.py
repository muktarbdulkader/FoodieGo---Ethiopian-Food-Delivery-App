#!/usr/bin/env python3
"""
Generate simple test notification sounds for FoodieGo app.

This script generates basic beep sounds that can be used for testing
the notification sound feature. For production, use professional sound files.

Requirements:
    pip install pydub numpy

Usage:
    python generate_test_sounds.py
    
This will create:
    - assets/sounds/notification.mp3 (800 Hz beep, 0.5 seconds)
    - assets/sounds/bell.mp3 (1200 Hz + 800 Hz bell-like sound, 0.8 seconds)
"""

import os
import numpy as np
from pydub import AudioSegment
from pydub.generators import Sine

def create_directory():
    """Create assets/sounds directory if it doesn't exist."""
    os.makedirs('assets/sounds', exist_ok=True)
    print("✓ Created assets/sounds directory")

def generate_notification_sound():
    """Generate a simple notification beep (800 Hz, 0.5 seconds)."""
    # Generate 800 Hz sine wave for 500ms
    duration_ms = 500
    frequency = 800
    
    # Create sine wave
    sine_wave = Sine(frequency).to_audio_segment(duration=duration_ms)
    
    # Apply fade in/out for smoother sound
    sine_wave = sine_wave.fade_in(50).fade_out(50)
    
    # Reduce volume slightly
    sine_wave = sine_wave - 6  # Reduce by 6 dB
    
    # Export as MP3
    output_path = 'assets/sounds/notification.mp3'
    sine_wave.export(output_path, format='mp3', bitrate='128k')
    print(f"✓ Generated {output_path}")

def generate_bell_sound():
    """Generate a bell-like sound (two-tone, 0.8 seconds)."""
    # Bell sound is typically a combination of frequencies
    # We'll use 1200 Hz and 800 Hz
    duration_ms = 800
    
    # Create two sine waves
    high_tone = Sine(1200).to_audio_segment(duration=duration_ms)
    low_tone = Sine(800).to_audio_segment(duration=duration_ms)
    
    # Mix them together (bell-like effect)
    bell = high_tone.overlay(low_tone)
    
    # Apply exponential decay (bell rings and fades)
    # Create fade out that simulates bell decay
    bell = bell.fade_out(600)
    
    # Reduce volume
    bell = bell - 6  # Reduce by 6 dB
    
    # Export as MP3
    output_path = 'assets/sounds/bell.mp3'
    bell.export(output_path, format='mp3', bitrate='128k')
    print(f"✓ Generated {output_path}")

def main():
    """Main function to generate all test sounds."""
    print("Generating test notification sounds...")
    print("=" * 50)
    
    try:
        create_directory()
        generate_notification_sound()
        generate_bell_sound()
        
        print("=" * 50)
        print("✓ All sounds generated successfully!")
        print("\nNext steps:")
        print("1. Run: flutter pub get")
        print("2. Run: flutter run")
        print("3. Test the sounds in Kitchen Orders page")
        print("\nNote: These are basic test sounds.")
        print("For production, consider using professional sound files.")
        
    except ImportError as e:
        print(f"\n✗ Error: Missing required package")
        print(f"  {e}")
        print("\nPlease install required packages:")
        print("  pip install pydub numpy")
        print("\nYou may also need ffmpeg:")
        print("  - macOS: brew install ffmpeg")
        print("  - Ubuntu: sudo apt-get install ffmpeg")
        print("  - Windows: Download from https://ffmpeg.org/")
        
    except Exception as e:
        print(f"\n✗ Error generating sounds: {e}")
        print("\nAlternative: Download free sounds from:")
        print("  - https://freesound.org/")
        print("  - https://mixkit.co/free-sound-effects/")

if __name__ == '__main__':
    main()
