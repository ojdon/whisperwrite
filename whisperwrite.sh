# Display message and wait for user to drag a video file into the terminal
echo "Please drag a video file into this terminal window to convert to audio and transcribe."
read -p "Drag file here and Press Enter: "

# Get the file path from the user input
video_file="$REPLY"

# Enclose the file path in double quotes to handle spaces
video_file="$video_file"

# Convert video to MP3 using ffmpeg
output_mp3="${video_file%.*}.mp3"
ffmpeg -i "$video_file" -vn -acodec libmp3lame -ar 44100 -ac 2 -ab 192k "$output_mp3"

echo "Conversion to MP3 completed. MP3 file saved as: $output_mp3"

# Run insanely-fast-whisper to transcribe
insanely-fast-whisper --file-name "$output_mp3" --transcript-path "$output_mp3.json" --batch-size 2 --device-id mps

# Remove the tempory audio file
rm "$output_mp3"

# Keep the terminal open until the user presses Enter
echo "Press Enter to close the terminal..."
read -r
