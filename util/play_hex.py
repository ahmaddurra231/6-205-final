import numpy as np
import sounddevice as sd

hex_filename = "output_hex_files/note_1_wave_16ksps.hex"
amplitude = 32767
offset = 0
sampling_rate = 16384

#Read HEX file
with open(hex_filename, 'r') as f:
    hex_lines = f.readlines()
audio_data_int16_loaded = np.array([int(line.strip(), 16) for line in hex_lines], dtype=np.uint16)

# Convert from unsigned to signed integers
audio_data_int16_loaded = audio_data_int16_loaded.astype(np.int16)

#Convert back to normalized audio data
audio_data_normalized_loaded = (audio_data_int16_loaded.astype(np.float32) - offset) / amplitude

#Play the reconstructed audio
print("Playing the reconstructed audio...")
sd.play(audio_data_normalized_loaded, samplerate=sampling_rate)
sd.wait()

