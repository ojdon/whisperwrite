#!/bin/bash

# Check if Git and Clang (part of Xcode) are not installed
if ! command -v git &> /dev/null && ! command -v clang &> /dev/null
then
    echo "Git and Clang are not installed. Installing now..."
    xcode-select --install
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
        echo "Error: Git or Clang installation failed. Please check your Xcode Command Line Tools setup."
        exit 1
    fi
fi

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
    brew install ffmpeg jq
    
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

# Check if the llama.cpp folder exists, if not one time setup
if [ ! -d "llama.cpp" ]; then
    # Add llama.cpp as a submodule
    git submodule add https://github.com/ggerganov/llama.cpp.git llama.cpp
    cd llama.cpp
    curl -L https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf --output ./models/llama-2-7b-chat.Q4_K_M.gguf
    LLAMA_METAL=1 make
    cd ..
fi


# Display message and wait for user to drag a video file into the terminal
echo "Please drag a video file into this terminal window to convert to audio and transcribe."
read -p "Drag file here and Press Enter: "

# Get the file path from the user input
video_file="$REPLY"

# Enclose the file path in double quotes to handle spaces
video_file="$(echo "$REPLY" | sed -E 's/[[:space:]]*'\''*$//')"

# Convert video to MP3 using ffmpeg
output_mp3="${video_file%.*}.mp3"
ffmpeg -i "$video_file" -vn -acodec libmp3lame -ar 44100 -ac 2 -ab 192k "$output_mp3"

echo "Conversion to MP3 completed. MP3 file saved as: $output_mp3"

# Run insanely-fast-whisper to transcribe
insanely-fast-whisper --file-name "$output_mp3" --transcript-path "$output_mp3.json" --batch-size 2 --device-id mps

# Remove the tempory audio file
rm "$output_mp3"

# Error handling for reading prompt
if [ ! -f "system_prompts/summary.txt" ]; then
    echo "Error: system_prompts/summary.txt not found."
    exit 1
fi
prompt=$(<system_prompts/summary.txt)

# Error handling for jq command
value=$(jq -r '.text' "$output_mp3.json")
if [ -z "$value" ]; then
    echo "Error: Unable to extract value from output.json using jq."
    exit 1
fi
# Run main with the prompt and output JSON
truncated_value=$(echo "$value" | cut -c 1-508)

./llama.cpp/main -m ./llama.cpp/models/llama-2-7b-chat.Q4_K_M.gguf -n 1024 -ngl 1 -p "$prompt for the following: $value" -c 4000 -b 4000 --temp 0.2



# Keep the terminal open until the user presses Enter
echo "Press Enter to close the terminal..."
read -r
