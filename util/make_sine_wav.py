import numpy as np

num_samples = 256
amplitude = 32767 #Max amplitude for 16-bit signed data
offset = 32768

#generate the since wave data
n = np.arange(num_samples)
sine_wave = amplitude * np.sin(2*np.pi * n /num_samples) + offset
sine_wave_uint_16 = sine_wave.astype(np.uint16)

#Wrtie data to hex file
with open('sine_wave_256_uint16.hex', 'w') as f:
    for value in sine_wave_uint_16:
        f.write('{:04X}\n'.format(value))