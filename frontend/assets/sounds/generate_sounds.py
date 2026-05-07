#!/usr/bin/env python3
"""
Generate placeholder MP3 notification sounds for FoodieGo Kitchen Dashboard.
Uses built-in Python libraries only - no external dependencies needed.
"""

import wave
import struct
import math
import os

def generate_wav_tone(filename, frequency=800, duration=1.0, sample_rate=44100, amplitude=0.5):
    """Generate a simple WAV tone file."""
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)   # 16-bit
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            # Apply fade in/out for smoother sound
            fade_duration = int(sample_rate * 0.05)  # 50ms fade
            
            if i < fade_duration:
                # Fade in
                fade = i / fade_duration
            elif i > num_samples - fade_duration:
                # Fade out
                fade = (num_samples - i) / fade_duration
            else:
                fade = 1.0
            
            value = int(32767 * amplitude * fade * math.sin(2 * math.pi * frequency * i / sample_rate))
            wav_file.writeframes(struct.pack('h', value))
    
    print(f"Generated: {filename}")

def generate_double_beep(filename, frequency=600, duration=0.5):
    """Generate two beeps with silence in between."""
    sample_rate = 44100
    samples_per_beep = int(sample_rate * duration)
    silence_samples = int(sample_rate * 0.2)  # 200ms silence
    total_samples = (samples_per_beep * 2) + silence_samples
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        # First beep
        for i in range(samples_per_beep):
            fade = 1.0
            if i < 2200:  # 50ms fade in
                fade = i / 2200
            elif i > samples_per_beep - 2200:  # 50ms fade out
                fade = (samples_per_beep - i) / 2200
            
            value = int(32767 * 0.5 * fade * math.sin(2 * math.pi * frequency * i / sample_rate))
            wav_file.writeframes(struct.pack('h', value))
        
        # Silence
        for _ in range(silence_samples):
            wav_file.writeframes(struct.pack('h', 0))
        
        # Second beep
        for i in range(samples_per_beep):
            fade = 1.0
            if i < 2200:
                fade = i / 2200
            elif i > samples_per_beep - 2200:
                fade = (samples_per_beep - i) / 2200
            
            value = int(32767 * 0.5 * fade * math.sin(2 * math.pi * frequency * i / sample_rate))
            wav_file.writeframes(struct.pack('h', value))
    
    print(f"Generated: {filename}")

def generate_sweep(filename, start_freq=400, end_freq=800, duration=0.8):
    """Generate a frequency sweep (ascending tone)."""
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = i / sample_rate
            freq = start_freq + (end_freq - start_freq) * (t / duration)
            
            fade = 1.0
            if i < 2200:  # Fade in
                fade = i / 2200
            elif i > num_samples - 2200:  # Fade out
                fade = (num_samples - i) / 2200
            
            value = int(32767 * 0.5 * fade * math.sin(2 * math.pi * freq * t))
            wav_file.writeframes(struct.pack('h', value))
    
    print(f"Generated: {filename}")

def main():
    print("=" * 60)
    print("FoodieGo Kitchen Dashboard - WAV Sound Generator")
    print("=" * 60)
    print()
    print("Generating placeholder notification sounds...")
    print("NOTE: These are WAV files. Convert to MP3 for production use.")
    print()
    
    # Get current directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Generate generic sounds
    print("[Generic Sounds]")
    generate_sweep("notification.wav", start_freq=600, end_freq=900, duration=0.6)
    generate_double_beep("bell.wav", frequency=700, duration=0.4)
    print()
    
    # Generate English placeholders
    print("[English Placeholders]")
    generate_sweep("waiter_call_en.wav", start_freq=600, end_freq=900, duration=0.8)
    generate_sweep("new_order_en.wav", start_freq=500, end_freq=800, duration=0.6)
    generate_sweep("order_ready_en.wav", start_freq=700, end_freq=1000, duration=0.7)
    print()
    
    # Generate Amharic placeholders (different frequencies)
    print("[Amharic Placeholders]")
    generate_wav_tone("waiter_call_am.wav", frequency=650, duration=0.9, amplitude=0.6)
    generate_double_beep("new_order_am.wav", frequency=550, duration=0.45)
    generate_wav_tone("order_ready_am.wav", frequency=850, duration=0.7)
    print()
    
    # Generate Oromo placeholders
    print("[Oromo Placeholders]")
    generate_wav_tone("waiter_call_om.wav", frequency=750, duration=0.85, amplitude=0.6)
    generate_double_beep("new_order_om.wav", frequency=620, duration=0.4)
    generate_sweep("order_ready_om.wav", start_freq=620, end_freq=920, duration=0.75)
    print()
    
    # Convert WAV to MP3 using lame if available
    print("=" * 60)
    print("Attempting to convert WAV to MP3...")
    print("=" * 60)
    
    wav_files = [
        "notification.wav",
        "bell.wav",
        "waiter_call_en.wav",
        "new_order_en.wav",
        "order_ready_en.wav",
        "waiter_call_am.wav",
        "new_order_am.wav",
        "order_ready_am.wav",
        "waiter_call_om.wav",
        "new_order_om.wav",
        "order_ready_om.wav",
    ]
    
    for wav_file in wav_files:
        mp3_file = wav_file.replace('.wav', '.mp3')
        # Try using ffmpeg if available
        result = os.system(f'ffmpeg -i "{wav_file}" -codec:a libmp3lame -qscale:a 2 "{mp3_file}" -y 2>nul')
        if result == 0:
            print(f"Converted: {wav_file} -> {mp3_file}")
            os.remove(wav_file)  # Remove WAV after successful conversion
        else:
            print(f"Note: {wav_file} created (MP3 conversion requires ffmpeg)")
    
    print()
    print("=" * 60)
    print("Sound generation complete!")
    print()
    print("To convert WAV files to MP3:")
    print("  1. Install ffmpeg: https://ffmpeg.org/download.html")
    print("  2. Run: ffmpeg -i input.wav -codec:a libmp3lame -qscale:a 2 output.mp3")
    print()
    print("Or use online converters:")
    print("  - https://cloudconvert.com/wav-to-mp3")
    print("  - https://convertio.co/wav-mp3/")
    print("=" * 60)

if __name__ == "__main__":
    main()
