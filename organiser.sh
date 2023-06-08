#!/bin/bash

src_dir="$1"
dest_dir="$2"
to_be_deleted=false
help=false

# Function to display script usage information
usage() {
  echo "Usage: $0 <SOURCE DIRECTORY> <DESTINATION DIRECTORY>"
  echo "Try 'Organiser.sh --help' for more information."
  exit 1
}

if [ "$*" = "-h" ] || [ "$*" = "--help" ]; then
  echo "Directory Organizer"
  echo "Usage: $0 <source_directory> <destination_directory> [-d] [-h]"
  echo
  echo "Description: This script organizes files from the source directory into separate"
  echo "folders based on their file extensions. The organized files are then moved or"
  echo "copied to the destination directory."
  echo
  echo "Arguments:"
  echo "  <source_directory>     Path to the source directory."
  echo "  <destination_directory> Path to the destination directory."
  echo "  -d                      Optional flag to delete original files after organizing."
  echo "  -h, --help              Display this help information."
  exit 0
fi
# Check arguments for syntax 
# Check the number of arguments
if [ $# -lt 2 ]; then
  usage
fi

# Check if the -d flag is provided
if [ "$3" = "-d" ]; then
  to_be_deleted=true
fi

# Check if the source directory exists
if [ ! -d "$src_dir" ]; then
  echo "Source directory does not exist!"
  usage
fi

# Create the destination directory if it doesn't exist
if [ ! -d "$dest_dir" ]; then
  mkdir -p "$dest_dir"
fi



# Organize files by extension
find "$src_dir" -type f | while read -r file; do
  # Get the file extension
  filename="$(basename "$file" | cut -d'.' -f1)"
  extension="$(basename "$file" | grep -o '\.[^.]*$')"
  
  if [ -z "$extension" ]; then
  extension="no_extension"
  else
  extension="${extension#.}"
  fi
  
  sub_dir="$dest_dir/$extension"

  # Create the subdirectory if it doesn't exist
  if [ ! -d "$sub_dir" ]; then
    mkdir -p "$sub_dir"
  fi
  
  # Handle duplicate filenames
  count=0
  new_file="$sub_dir/$(basename "$file")"
  while [ -e "$new_file" ]; do
    ((count++))
    filename="$(basename "$file" | cut -d'.' -f1)"
    if [ $extension = "no_extension" ]; then
    new_file="$sub_dir/${filename}_$count"
    else
    new_file="$sub_dir/${filename}_$count.$extension"
    fi
  done
  
  # Move or copy the file to the destination
  if [ "$to_be_deleted" = true ]; then
    mv "$file" "$new_file"
  else
    cp "$file" "$new_file"
  fi
done