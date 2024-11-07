import numpy as np

# Parameters
num_samples = 256
amplitude = 127  # Max amplitude for 8-bit data
offset = 128     # Offset to shift to unsigned range

# Generate the sine wave data
n = np.arange(num_samples)
sine_wave = amplitude * np.sin(2 * np.pi * n / num_samples) + offset
sine_wave_uint8 = sine_wave.astype(np.uint8)

# Write the data to a HEX file
with open('sine_wave_256.hex', 'w') as f:
    for value in sine_wave_uint8:
        f.write('{:02X}\n'.format(value))
