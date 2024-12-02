

# #generate 16ksps sine wave
# import numpy as np

# num_samples = 8192        
# sampling_rate = 16000     
# amplitude = 32767          
# offset = 0                

# # Calculate the frequency of the sine wave
# frequency = sampling_rate / num_samples  # Approximately 1.953125 Hz

# print(f"Generating a {frequency} Hz sine wave with {num_samples} samples at {sampling_rate} Sps.")

# # Generate the sine wave data
# n = np.arange(num_samples)
# sine_wave = amplitude * np.sin(2 * np.pi * frequency * n / sampling_rate) + offset
# sine_wave_int16 = sine_wave.astype(np.int16)

# # Write the data to a HEX file
# hex_filename = f'sine_wave_16ksps.hex'
# with open(hex_filename, 'w') as f:
#     for value in sine_wave_int16:
#         # Convert signed int16 to unsigned for HEX representation
#         hex_value = int(value) & 0xFFFF
#         f.write('{:04X}\n'.format(hex_value))

# print(f"16-bit sine wave written to {hex_filename}.")


# # Generate 16-bit sine_wave
# import numpy as np

# # Parameters
# num_samples = 256
# amplitude = 32767  # Max amplitude for 16-bit signed data
# offset = 0         # No offset needed for signed integers

# # Generate the sine wave data
# n = np.arange(num_samples)
# sine_wave = amplitude * np.sin(2 * np.pi * n / num_samples) + offset
# sine_wave_int16 = sine_wave.astype(np.int16)

# # Write the data to a HEX file
# with open('sine_wave_256_16bit.hex', 'w') as f:
#     for value in sine_wave_int16:
#         # Convert signed int16 to unsigned for HEX representation
#         hex_value = int(value) & 0xFFFF
#         f.write('{:04X}\n'.format(hex_value))


#original code - works if we change parameters


import numpy as np

# Parameters
num_samples = 256
amplitude = 32767  # Max amplitude for 16-bit signed data
offset = 32768     # Offset to shift to unsigned range

# Generate the sine wave data
n = np.arange(num_samples)
sine_wave = amplitude * np.sin(2 * np.pi * n / num_samples) + offset
sine_wave_uint16 = sine_wave.astype(np.uint16)

# Write the data to a HEX file
with open('sine_wave_256_uint16.hex', 'w') as f:
    for value in sine_wave_uint16:
        f.write('{:04X}\n'.format(value))
