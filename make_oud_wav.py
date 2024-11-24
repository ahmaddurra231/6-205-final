import numpy as np
import librosa
import matplotlib.pyplot as plt

# Parameters
input_audio_file = "oud_01.wav"  

#adjust the following values:
sampling_rate = 22050  
num_samples = 256  
amplitude = 127 
offset = 128  

#Step 1: Load the Oud sample using librosa
print("Loading Oud sample...")
audio_data, sr = librosa.load(input_audio_file, sr=sampling_rate)
print(f"Loaded audio file with {len(audio_data)} samples at {sr} Hz.")

# Step 2: Extract a portion of the waveform (trim silence and select a segment)
audio_data, _ = librosa.effects.trim(audio_data)
duration = 0.5  # Duration in seconds to extract
sample_count = min(int(duration * sr), len(audio_data))
oud_wave = audio_data[:sample_count]

# Step 3: Resample the waveform to 256 samples
oud_wave_resampled = librosa.resample(oud_wave, orig_sr=sr, target_sr=num_samples)
oud_wave_resampled = oud_wave_resampled[:num_samples]  # Ensure exactly 256 samples

# Step 4: Normalize the waveform and convert to 8-bit unsigned integers
oud_wave_normalized = oud_wave_resampled / np.max(np.abs(oud_wave_resampled))
oud_wave_uint8 = (oud_wave_normalized * amplitude + offset).astype(np.uint8)

# Step 5: Save the waveform to a HEX file
hex_filename = "oud_01_wave_256.hex"
with open(hex_filename, 'w') as f:
    for value in oud_wave_uint8:
        f.write(f"{value:02X}\n")

print(f"Waveform saved to {hex_filename}")

# Step 6: Plot the waveform
plt.plot(oud_wave_uint8)
plt.title("Oud Waveform (Resampled and Normalized)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude (8-bit)")
plt.grid()
plt.show()