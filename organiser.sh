#!/bin/bash

# Function to print usage instructions
print_usage() {
  echo "Usage: bash organizer.sh <srcdir> <destdir> [options]"
  echo "Options:"
  echo "  -s <style>     Specify organization style: ext (default) or date"
  echo "  -d             Delete original files after organizing"
  echo "  -e <excludes>  Exclude file types or directories (comma-separated)"
  echo "  -l <logfile>   Generate a log file with the specified name"
  echo "  -c <extension> Compress all the files together with a particular extension"
}
folders_count=0;
files_count=0;
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
  local actualname="$(basename "$src_file")"
  if [ -e "$dest_path" ]; then
    local counter=1
    #loop to dest update file name for files with same name 
    while [ -e "$dest_path" ]; do  
      filename="${actualname%.*}_$counter.${filename##*.}"
      dest_path="$dest_folder/$filename"
      ((counter++))
    done
  fi
  
  ((files_count++))
  
  if [ "$delete_files" = true ]; then
  mv "$src_file" "$dest_path"
  else
  cp "$src_file" "$dest_path"
  fi  
  
  if [ -n "$logfile" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $src_file | $dest_path" >> "$logfile"
  fi
}

# Function to compress files in a folder using tar
compress_files() {
  local folder="$1"
  local output_file="$2"
  
  # Check if the folder exists
  if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    return 1
  fi
  
  # Check if there are any files in the folder
  if [ -z "$(ls -A "$folder")" ]; then
    echo "Folder '$folder' is empty."
    return 1
  fi
  
  # Create the compressed tarball
  if ! tar -czf "$output_file" -C "$(dirname "$folder")" "$(basename "$folder")"; then
    echo "Failed to create the compressed tarball."
    return 1
  fi
  
  echo "Compressed tarball '$output_file' created successfully."
}

# Parsing command-line arguments
while getopts "s:de:l:c:" opt; do
  case $opt in
    s)
      style=$OPTARG
      ;;
    d)
      delete_files=true
      ;;
    e)
      excludes=,,$OPTARG,,
      ;;
    l)
      logfile=$OPTARG
      ;;
    c)
      to_be_zipped=,,$OPTARG,,
      ;;
    # Handling errors in giving arguments to options
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
    
    # Excluding the files
    if [ -n "$excludes" ] && [[ "$excludes" == *,"$extension",* ]]; then
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
    
    if [ -n "$excludes" ] && [[ "$excludes" == *,"$creation_date",* ]]; then
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
echo "$to_be_zipped"

# Compressing specific files using tar
if [ -n "$to_be_zipped" ]; then
  echo "Compressing specific files..."
  IFS=',' read -ra zip_args <<< "$to_be_zipped"
  while IFS= read -r -d '' folder; do
    folder_name="$(basename "$folder")"
    for arg in "${zip_args[@]}"; do
      if [ "$arg" = "$folder_name" ]; then
        tar_name="${folder_name}.tar.gz"
        compress_files "$folder" "$destdir/$tar_name"
        rm -rf "$folder"
        ((folders_count--))
        break
      fi
    done
  done < <(find "$destdir" -type d -print0)
fi

# moving the file to destination
if [ -n "$logfile" ]; then
mv "$logfile" "$destdir/$logfile"
fi

# Printing summary
echo "Summary:"
echo "Number of folders created: $folders_count"
echo "Number of files transferred: $files_count"
# logic for recursively finding the no. of files transferred in each folder 
find "$destdir" -type d -not -path "$destdir" -exec sh -c "echo -n '{}: '; find '{}' -type f | wc -l" \; | sed 's/^/    /'

# Cleanup :-)
unset style
unset delete_files
unset excludes
unset logfile
unset srcdir
unset destdir
