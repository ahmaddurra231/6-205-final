import numpy as np
import librosa


input_audio_file = "oud_01.wav"
sampling_rate = 16384  
amplitude = 32767  
offset = 0  
desired_samples = 8192  

#Load the Oud sample with a duration of 1 second
print("Loading Oud sample...")

audio_data, sr = librosa.load(input_audio_file, sr=sampling_rate, mono=True, duration=1.0)
print(f"Loaded audio file with {len(audio_data)} samples at {sr} Hz.")

#Ensure the audio data has exactly the desired samples
if len(audio_data) > desired_samples:
    audio_data = audio_data[:desired_samples] #trim
elif len(audio_data) < desired_samples:
    # Pad with zeros to reach 256 samples
    audio_data = np.pad(audio_data, (0, desired_samples - len(audio_data)), 'constant')

# Normalize 
audio_data_normalized = audio_data / np.max(np.abs(audio_data))

# Convert to 16-bit signed integers
audio_data_int16 = (audio_data_normalized * amplitude + offset).astype(np.int16)
print("Converted audio data to 16-bit signed integers.")

# Save the waveform to a HEX file
hex_filename = "oud_01_wave_16ksps.hex"
with open(hex_filename, 'w') as f:
    for value in audio_data_int16:
        # Convert value to unsigned 16-bit HEX
        hex_value = int(value) & 0xFFFF
        f.write(f"{hex_value:04X}\n")
print(f"Waveform saved to {hex_filename}")


# # Step 6: Plot the waveform
# plt.plot(oud_wave_uint8)
# plt.title("Oud Waveform (Resampled and Normalized)")
# plt.xlabel("Sample Index")
# plt.ylabel("Amplitude (8-bit)")
# plt.grid()
# plt.show()



