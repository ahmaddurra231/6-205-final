import numpy as np

num_samples = 256
amplitude = 32767  # Max amplitude for 16-bit signed data
offset = 32768

# Generate the square wave data
n = np.arange(num_samples)
square_wave = amplitude * np.sign(np.sin(2 * np.pi * n / num_samples)) + offset
square_wave_uint_16 = square_wave.astype(np.uint16)

# Write data to hex file
with open('square_wave_256_uint16.hex', 'w') as f:
    for value in square_wave_uint_16:
        f.write('{:04X}\n'.format(value))

