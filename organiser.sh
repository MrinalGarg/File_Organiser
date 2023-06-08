#!/bin/bash

# Function to print usage instructions
print_usage() {
  echo "Usage: bash organizer.sh <srcdir> <destdir> [options]"
  echo "Options:"
  echo "  -s <style>    Specify organization style: ext (default) or date"
  echo "  -d            Delete original files after organizing"
  echo "  -e <excludes> Exclude file types or directories (comma-separated)"
  echo "  -l <logfile>  Generate a log file with the specified name"
}
folders_count=0;
# Function to create a folder if it doesn't exist
create_folder() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    ((folders_count++))
  fi
}

# Function to move files to the destination folder
move_file() {
  local src_file="$1"
  local dest_folder="$2"
  local filename="$(basename "$src_file")"
  local dest_path="$dest_folder/$filename"
  
  if [ -e "$dest_path" ]; then
    local counter=1
    while [ -e "$dest_path" ]; do
      filename="${filename%.*}_$counter.${filename##*.}"
      dest_path="$dest_folder/$filename"
      ((counter++))
    done
  fi
  
  cp "$src_file" "$dest_path"
  
  if [ -n "$logfile" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $src_file | $dest_path" >> "$logfile"
  fi
}

# Parsing command-line arguments
while getopts "s:de:l:" opt; do
  case $opt in
    s)
      style=$OPTARG
      ;;
    d)
      delete_files=true
      ;;
    e)
      excludes=$OPTARG
      ;;
    l)
      logfile=$OPTARG
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      print_usage
      exit 1
      ;;
    \?)
      echo "Error: Invalid option -$OPTARG."
      print_usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

# Checking source and destination directory arguments
if [ $# -lt 2 ]; then
  echo "Error: Both source and destination directory paths are required."
  print_usage
  exit 1
fi

srcdir=$1
destdir=$2

# Checking and creating destination folder
create_folder "$destdir"

# File organization based on extension
if [ -z "$style" ] || [ "$style" = "ext" ]; then
  echo "Organizing files based on extension..."
  
  while IFS= read -r -d '' file; do
    extension="${file##*.}"
    
    if [ -n "$excludes" ] && [[ "$excludes" == *"$extension"* ]]; then
      continue
    fi
    
    if [[ ! "$file" = *.* ]]; then
      dest_folder="$destdir/no_extension"
    else
      dest_folder="$destdir/$extension"
    fi
    
    create_folder "$dest_folder"
    move_file "$file" "$dest_folder"
  done < <(find "$srcdir" -type f -print0)
fi

# File organization based on creation date
if [ "$style" = "date" ]; then
  echo "Organizing files based on creation date..."
  
  while IFS= read -r -d '' file; do
    creation_date=$(stat -c "%y" "$file" | cut -d' ' -f1)
    
    if [ -n "$excludes" ] && [[ "$excludes" == *"$creation_date"* ]]; then
      continue
    fi
    
    if [ -z "$creation_date" ]; then
      dest_folder="$destdir/no_date"
    else
      dest_folder="$destdir/$creation_date"
    fi
    
    create_folder "$dest_folder"
    move_file "$file" "$dest_folder"
  done < <(find "$srcdir" -type f -print0)
fi

# Deleting original files
if [ "$delete_files" = true ]; then
  echo "Deleting original files..."
  
  while IFS= read -r -d '' file; do
    rm "$file"
  done < <(find "$srcdir" -type f -print0)
fi

# Printing summary
echo "Summary:"
#folders_count=$(find "$destdir" -mindepth 1 -type d | grep -v "$destdir$" | wc -l)
files_count=$(find "$destdir" -type f | wc -l)
echo "Number of folders created: $folders_count"
echo "Number of files transferred: $files_count"

# Cleanup
unset style
unset delete_files
unset excludes
unset logfile
unset srcdir
unset destdir
