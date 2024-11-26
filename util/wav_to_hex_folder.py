import os
import numpy as np
import librosa

def wav_to_hex(input_dir, output_dir, sampling_rate=16384, amplitude=32767, desired_samples=8192):
    """
    Converts all WAV files in the input directory to HEX files in the output directory.

    Parameters:
    - input_dir (str): Path to the directory containing input WAV files.
    - output_dir (str): Path to the directory where HEX files will be saved.
    - sampling_rate (int): Desired sampling rate for the audio files. Default is 16384 Hz.
    - amplitude (int): Amplitude scaling factor for 16-bit audio. Default is 32767.
    - desired_samples (int): Number of samples each audio file should have. Default is 8192.
    """
    # Ensure the input directory exists
    if not os.path.isdir(input_dir):
        print(f"Error: Input directory '{input_dir}' does not exist.")
        return

    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # List all WAV files in the input directory
    wav_files = [f for f in os.listdir(input_dir) if f.lower().endswith('.wav')]

    if not wav_files:
        print(f"No WAV files found in the input directory '{input_dir}'.")
        return

    print(f"Found {len(wav_files)} WAV file(s) in '{input_dir}'. Processing...")

    for wav_file in wav_files:
        input_path = os.path.join(input_dir, wav_file)
        base_name = os.path.splitext(wav_file)[0]
        hex_filename = f"{base_name}_wave_16ksps.hex"
        hex_path = os.path.join(output_dir, hex_filename)

        print(f"\nProcessing '{wav_file}'...")

        try:
            # Step 1: Load the WAV file with the specified sampling rate
            audio_data, sr = librosa.load(input_path, sr=sampling_rate, mono=True, duration=None)
            print(f"Loaded '{wav_file}' with {len(audio_data)} samples at {sr} Hz.")

            # Step 2: Trim or pad the audio data to have exactly 'desired_samples' samples
            if len(audio_data) > desired_samples:
                audio_data = audio_data[:desired_samples]
                print(f"Trimmed to {desired_samples} samples.")
            elif len(audio_data) < desired_samples:
                padding_length = desired_samples - len(audio_data)
                audio_data = np.pad(audio_data, (0, padding_length), 'constant')
                print(f"Padded with {padding_length} zeros to reach {desired_samples} samples.")
            else:
                print(f"Audio data already has {desired_samples} samples.")

            # Step 3: Normalize the audio data to the range [-1, 1]
            max_val = np.max(np.abs(audio_data))
            if max_val == 0:
                audio_data_normalized = audio_data
                print("Warning: Audio data is silent. No normalization applied.")
            else:
                audio_data_normalized = audio_data / max_val
                print("Normalized audio data to range [-1, 1].")

            # Step 4: Convert normalized audio data to 16-bit signed integers
            audio_data_int16 = (audio_data_normalized * amplitude).astype(np.int16)
            print("Converted audio data to 16-bit signed integers.")

            # Step 5: Save the waveform to a HEX file
            with open(hex_path, 'w') as f:
                for value in audio_data_int16:
                    # Convert value to unsigned 16-bit HEX
                    hex_value = int(value) & 0xFFFF
                    f.write(f"{hex_value:04X}\n")
            print(f"Saved HEX file to '{hex_path}'.")

        except Exception as e:
            print(f"Error processing '{wav_file}': {e}")

    print("\nAll files have been processed successfully.")

if __name__ == "__main__":
    # Configuration
    INPUT_DIRECTORY = "extracted_notes"    # Replace with your input directory path
    OUTPUT_DIRECTORY = "output_hex_files"  # Replace with your desired output directory path

    # Optional: Customize parameters if needed
    SAMPLING_RATE = 16384    # 16 kHz
    AMPLITUDE = 32767        # Maximum amplitude for 16-bit audio
    DESIRED_SAMPLES = 8192   # Number of samples per HEX file

    # Run the conversion
    wav_to_hex(
        input_dir=INPUT_DIRECTORY,
        output_dir=OUTPUT_DIRECTORY,
        sampling_rate=SAMPLING_RATE,
        amplitude=AMPLITUDE,
        desired_samples=DESIRED_SAMPLES
    )
