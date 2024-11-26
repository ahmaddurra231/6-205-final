import os
import librosa
import soundfile as sf
import numpy as np

def extract_notes_onset(input_file, output_dir, num_notes=8, hop_length=512, backtrack=True, pre_max=20, post_max=20, pre_avg=100, post_avg=100, delta=0.2, wait=0):
    """
    Extracts the first `num_notes` from an audio file based on onset detection and saves them as separate WAV files.

    Parameters:
    - input_file (str): Path to the input audio file.
    - output_dir (str): Directory where the extracted WAV files will be saved.
    - num_notes (int): Number of notes to extract. Default is 8.
    - hop_length (int): Number of samples between successive frames. Default is 512.
    - backtrack (bool): Whether to backtrack to the nearest preceding offset. Default is True.
    - pre_max (int): Maximum number of frames to consider before the current frame for local max. Default is 20.
    - post_max (int): Maximum number of frames to consider after the current frame for local max. Default is 20.
    - pre_avg (int): Number of frames to use for the average before the current frame. Default is 100.
    - post_avg (int): Number of frames to use for the average after the current frame. Default is 100.
    - delta (float): Threshold relative to the maximum peak for onset detection. Default is 0.2.
    - wait (int): Minimum number of frames to wait between onsets. Default is 0.
    """
    # Load the audio file
    print(f"Loading audio file: {input_file}")
    try:
        y, sr = librosa.load(input_file, sr=None, mono=True)  # Preserve original sample rate
    except FileNotFoundError:
        print(f"Error: The file '{input_file}' was not found.")
        return
    except Exception as e:
        print(f"Error loading audio file: {e}")
        return

    # Perform onset detection
    print("Detecting onsets...")
    onsets = librosa.onset.onset_detect(y=y, sr=sr, hop_length=hop_length, backtrack=backtrack,
                                        pre_max=pre_max, post_max=post_max,
                                        pre_avg=pre_avg, post_avg=post_avg,
                                        delta=delta, wait=wait)
    
    if len(onsets) == 0:
        print("No onsets detected. Please adjust the onset detection parameters.")
        return

    # Convert onset frames to sample indices
    onset_samples = librosa.frames_to_samples(onsets, hop_length=hop_length)

    # Ensure the list is sorted and unique
    onset_samples = sorted(set(onset_samples))

    selected_onsets = onset_samples[:num_notes]

    os.makedirs(output_dir, exist_ok=True)

    # Extract and save each note as a separate WAV file
    print(f"Exporting the first {num_notes} notes to '{output_dir}' directory...")
    for i, onset in enumerate(selected_onsets):
        # Define the start and end samples
        start_sample = onset
        if i < len(selected_onsets) - 1:
            end_sample = selected_onsets[i + 1]
        else:
            end_sample = len(y)  # Last note goes till the end

        # Extract the note
        note = y[start_sample:end_sample]

        wav_filename = os.path.join(output_dir, f"note_{i+1}.wav")

        sf.write(wav_filename, note, sr)
        print(f"Saved: {wav_filename}")

    print("Extraction complete.")

if __name__ == "__main__":
    INPUT_AUDIO = "oud_octave.mpeg"         
    OUTPUT_DIRECTORY = "extracted_notes"     
    NUMBER_OF_NOTES = 8                     

    # Onset detection parameters 
    HOP_LENGTH = 512          
    BACKTRACK = True          
    PRE_MAX = 20              
    POST_MAX = 20            
    PRE_AVG = 100           
    POST_AVG = 100        
    DELTA = 0.2          
    WAIT = 0             

    extract_notes_onset(
        input_file=INPUT_AUDIO,
        output_dir=OUTPUT_DIRECTORY,
        num_notes=NUMBER_OF_NOTES,
        hop_length=HOP_LENGTH,
        backtrack=BACKTRACK,
        pre_max=PRE_MAX,
        post_max=POST_MAX,
        pre_avg=PRE_AVG,
        post_avg=POST_AVG,
        delta=DELTA,
        wait=WAIT
    )
