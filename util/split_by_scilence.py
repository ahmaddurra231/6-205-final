import os
from pydub import AudioSegment, silence

def extract_notes(input_file, output_dir, num_notes=8, min_silence_len=300, silence_thresh=-40, keep_silence=100):
    """
    Extracts the first `num_notes` from an audio file based on silence and saves them as separate WAV files.

    Parameters:
    - input_file (str): Path to the input audio file.
    - output_dir (str): Directory where the extracted WAV files will be saved.
    - num_notes (int): Number of notes to extract. Default is 8.
    - min_silence_len (int): Minimum length of silence (in ms) to consider a split. Default is 300ms.
    - silence_thresh (int): Silence threshold in dBFS. Segments quieter than this are considered silence. Default is -40dBFS.
    - keep_silence (int): Amount of silence to retain at the beginning and end of each chunk (in ms). Default is 100ms.
    """
    # Load the audio file
    print(f"Loading audio file: {input_file}")
    audio = AudioSegment.from_file(input_file)

    # Split the audio into chunks based on silence
    print("Splitting audio into chunks based on silence...")
    chunks = silence.split_on_silence(
        audio,
        min_silence_len=min_silence_len,
        silence_thresh=silence_thresh,
        keep_silence=keep_silence
    )

    if not chunks:
        print("No chunks detected. Please adjust the silence parameters.")
        return

    selected_chunks = chunks[:num_notes]

    os.makedirs(output_dir, exist_ok=True)

    # Export each chunk as a separate WAV file
    print(f"Exporting the first {num_notes} notes to '{output_dir}' directory...")
    for i, chunk in enumerate(selected_chunks):
        wav_filename = os.path.join(output_dir, f"note_{i+1}.wav")
        chunk.export(wav_filename, format="wav")
        print(f"Saved: {wav_filename}")

    print("Extraction complete.")

if __name__ == "__main__":
    INPUT_AUDIO = "oud_octave.mpeg"   
    OUTPUT_DIRECTORY = "extracted_notes"  
    NUMBER_OF_NOTES = 8                

    # Silence detection parameters 
    MIN_SILENCE_LENGTH = 300  
    SILENCE_THRESHOLD = -40   
    KEEP_SILENCE_DURATION = 100  

    extract_notes(
        input_file=INPUT_AUDIO,
        output_dir=OUTPUT_DIRECTORY,
        num_notes=NUMBER_OF_NOTES,
        min_silence_len=MIN_SILENCE_LENGTH,
        silence_thresh=SILENCE_THRESHOLD,
        keep_silence=KEEP_SILENCE_DURATION
    )
