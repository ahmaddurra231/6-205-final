import numpy as np

num_samples = 256
amplitude = 32767  # Max amplitude for 16-bit signed data
offset = 32768

# Generate the sawtooth wave data
n = np.arange(num_samples)
sawtooth_wave = (2 * amplitude * (n / num_samples)) - amplitude + offset
sawtooth_wave_uint_16 = sawtooth_wave.astype(np.uint16)

# Write data to hex file
with open('sawtooth_wave_256_uint16.hex', 'w') as f:
    for value in sawtooth_wave_uint_16:
        f.write('{:04X}\n'.format(value))

