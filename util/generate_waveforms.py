import numpy as np

# Constants
NUM_SAMPLES = 256
AMPLITUDE = 128  # Half of 8-bit range (0x80 midpoint)
OFFSET = 128     # Offset to shift range from -128 to 0–255

# Function to generate a sine wave (256 samples)
def generate_sine_wave(samples):
    return [int(AMPLITUDE * np.sin(2 * np.pi * i / samples) + OFFSET) for i in range(samples)]

# Function to generate a sawtooth wave (256 samples)
def generate_sawtooth_wave(samples):
    return [int((i / samples) * 255) for i in range(samples)]

# Function to generate a square wave (256 samples)
def generate_square_wave(samples):
    half = samples // 2
    return [255 if i < half else 0 for i in range(samples)]

# Generate waves
sine_wave = generate_sine_wave(NUM_SAMPLES)
sawtooth_wave = generate_sawtooth_wave(NUM_SAMPLES)
square_wave = generate_square_wave(NUM_SAMPLES)

# Print hexadecimal values for each wave
def print_hex(wave, name):
    print(f"\n{name} Wave (Hex):")
    print(" ".join(f"{x:02X}" for x in wave))

print_hex(sine_wave, "Sine")
print_hex(sawtooth_wave, "Sawtooth")
print_hex(square_wave, "Square")

# Save to files
def save_to_hex_file(wave, filename):
    with open(filename, 'w') as f:
        for value in wave:
            f.write(f"{value:02X}\n")

save_to_hex_file(sine_wave, "sine_wave.hex")
save_to_hex_file(sawtooth_wave, "sawtooth_wave.hex")
save_to_hex_file(square_wave, "square_wave.hex")

print("\nHex files generated: sine_wave.hex, sawtooth_wave.hex, square_wave.hex")



# # generate_instrument_waveform.py

# import numpy as np

# # Parameters
# num_samples = 256          # Number of samples in one period
# amplitude = 127            # Max amplitude for 8-bit data (for 8-bit signed: -128 to 127)
# offset = 128               # Offset to shift to unsigned range (0 to 255)
# instrument_name = 'oud'    # Name of the instrument

# # Harmonic coefficients for different instruments
# # These coefficients are illustrative; adjust them to refine the sound
# instruments = {
#     'piano': [1.0, 0.5, 0.3, 0.2, 0.1],
#     'oud':   [1.0, 0.7, 0.5, 0.3, 0.2, 0.1, 0.05],
#     'guitar': [1.0, 0.7, 0.5, 0.3, 0.1]
# }

# # Choose instrument harmonics
# harmonics = instruments.get(instrument_name.lower(), instruments['oud'])

# # Generate the waveform
# n = np.arange(num_samples)
# waveform = np.zeros(num_samples)
# for k, amplitude_coeff in enumerate(harmonics):
#     harmonic_number = k + 1
#     waveform += amplitude_coeff * np.sin(2 * np.pi * harmonic_number * n / num_samples)

# # Normalize the waveform
# waveform = waveform / np.max(np.abs(waveform))

# # Scale to desired amplitude and offset
# waveform = amplitude * waveform + offset

# # Convert to unsigned 8-bit integer
# waveform_uint8 = np.clip(waveform, 0, 255).astype(np.uint8)

# # Save to hex file
# hex_filename = f'{instrument_name}_waveform_{num_samples}.hex'
# with open(hex_filename, 'w') as f:
#     for value in waveform_uint8:
#         f.write('{:02X}\n'.format(value))

# print(f"{instrument_name.capitalize()} waveform written to {hex_filename}.")

