#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew is not installed. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    
    # Check if Homebrew installation was successful
    if [ $? -ne 0 ]; then
        echo "Error: Homebrew installation failed. Please check your internet connection and try again."
        exit 1
    fi
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg is not installed. Installing now..."
    brew install ffmpeg
    
    # Check if ffmpeg installation was successful
    if [ $? -ne 0 ]; then
        echo "Error: ffmpeg installation failed. Please check your Homebrew setup."
        exit 1
    fi
fi

# Check if insanely-fast-whisper is installed
if ! command -v insanely-fast-whisper &> /dev/null
then
    # Install insanely-fast-whisper using pip3
    echo "insanely-fast-whisper is not installed. Installing now..."
    pip3 install insanely-fast-whisper

    # Check if installation was successful
    if [ $? -ne 0 ]; then
        echo "Error: Installation failed. Please check your pip3 setup."
        exit 1
    fi
fi

# Display message and wait for user to drag a video file into the terminal
echo "Please drag a video file into this terminal window to convert to MP3 and transcribe."
read -p "Press Enter to continue..."

# Get the file path from the user input and trim trailing spaces
video_file="${REPLY%"${REPLY##*[![:space:]]}"}"

# Convert video to MP3 using ffmpeg
output_mp3="${video_file%.*}.mp3"
ffmpeg -i "$video_file" -vn -acodec libmp3lame -ar 44100 -ac 2 -ab 192k "$output_mp3"

echo "Conversion to MP3 completed. MP3 file saved as: $output_mp3"

# Run insanely-fast-whisper with the provided arguments
insanely-fast-whisper --file-name "$output_mp3" --batch-size 2 --device-id mps

# Keep the terminal open until the user presses Enter
echo "Press Enter to close the terminal..."
read -r


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
