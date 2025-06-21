#!/bin/sh
# PNG to ICNS v1.0 - https://github.com/BenSouchet/png-to-icns
# Copyright(C) 2022 Ben Souchet, 2025 Jacob Nilsson | MIT License

usage() {
  echo "Usage: $0 -i <input image> -o <output.icns>"
  exit 1
}

while getopts "hi:o:" opt; do
  case "$opt" in
    h) usage ;;
    i) input="$OPTARG" ;;
    o) output="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$input" ] || [ -z "$output" ]; then
  echo "ERROR: both -i and -o are required"
  usage
fi

if [ ! -f "$input" ]; then
  echo "ERROR: input file '$input' does not exist"
  exit 1
fi

tmpdir=$(mktemp -d)
if [ ! -d "$tmpdir" ]; then
  echo "ERROR: failed to create temp directory"
  exit 1
fi

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM

input_ext="${input##*.}"
input_ext_lower=$(printf '%s\n' "$input_ext" | tr '[:upper:]' '[:lower:]')
if [ "$input_ext_lower" != "png" ]; then
  input_png="$tmpdir/input.png"
  convert "$input" "$input_png"
  if [ $? -ne 0 ]; then
    echo "ERROR: failed to convert input image to PNG"
    exit 1
  fi
else
  input_png="$input"
fi

iconset="$tmpdir/icon.iconset"
mkdir "$iconset"

sizes="16 32 128 256 512 1024"
for size in $sizes; do
  sips -z "$size" "$size" "$input_png" --out "$iconset/icon_${size}x${size}.png" >/dev/null 2>&1
  sips -z $((size * 2)) $((size * 2)) "$input_png" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null 2>&1
done

iconutil -c icns "$iconset" -o "$output"

if [ $? -eq 0 ] && [ -f "$output" ]; then
  echo "Icon successfully created at: $output"
else
  echo "ERROR: failed to create icon"
  exit 1
fi
