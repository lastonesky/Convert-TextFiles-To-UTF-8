#!/usr/bin/env bash
set -euo pipefail

folder=""
patterns="*.cs,*.vb,*.aspx"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -folder)
      folder="${2:-}"
      shift 2
      ;;
    -patterns)
      patterns="${2:-}"
      shift 2
      ;;
    -h|--help)
      script_name="$(basename "$0")"
      echo "Usage: ./$script_name -folder <directory> [-patterns <pattern1,pattern2,...>]"
      echo "Example 1: ./$script_name -folder ."
      echo "Example 2: ./$script_name -folder /path/to/your/project/App_Code"
      echo "Example 3: ./$script_name -folder . -patterns \"*.cs,*.vb,*.aspx\""
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

script_name="$(basename "$0")"
if [[ -z "$folder" ]]; then
  echo "Usage: ./$script_name -folder <directory> [-patterns <pattern1,pattern2,...>]"
  echo "Example 1: ./$script_name -folder ."
  echo "Example 2: ./$script_name -folder /path/to/your/project/App_Code"
  echo "Example 3: ./$script_name -folder . -patterns \"*.cs,*.vb,*.aspx\""
  exit 1
fi

if [[ ! -d "$folder" ]]; then
  echo "Invalid folder: $folder"
  exit 1
fi

IFS=',' read -r -a pattern_array <<< "$patterns"
find_expr=()
for i in "${!pattern_array[@]}"; do
  p="$(echo "${pattern_array[$i]}" | xargs)"
  if [[ -z "$p" ]]; then
    continue
  fi
  if [[ ${#find_expr[@]} -gt 0 ]]; then
    find_expr+=(-o)
  fi
  find_expr+=(-name "$p")
done

if [[ ${#find_expr[@]} -eq 0 ]]; then
  echo "No valid patterns provided."
  exit 1
fi

mapfile -d '' files < <(find "$folder" -type f \( "${find_expr[@]}" \) -print0)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No matching files found under: $folder ; patterns: $patterns"
  exit 0
fi

locale_encoding="$(locale charmap 2>/dev/null || true)"
if [[ -z "$locale_encoding" ]]; then
  locale_encoding="UTF-8"
fi

for file in "${files[@]}"; do
  bom_hex="$(head -c 3 "$file" | od -An -t x1 | tr -d ' \n')"
  if [[ "$bom_hex" == "efbbbf" ]]; then
    echo "[SKIP] $file (Already UTF-8 BOM)"
    continue
  fi

  tmp_file="$(mktemp)"
  if iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1; then
    printf '\xEF\xBB\xBF' > "$tmp_file"
    cat "$file" >> "$tmp_file"
    mv "$tmp_file" "$file"
    echo "[NORMALIZED] $file (UTF-8 no BOM -> UTF-8 BOM)"
    continue
  fi

  converted=0
  for enc in GB18030 GBK "$locale_encoding" CP1252 LATIN1; do
    if iconv -f "$enc" -t UTF-8 "$file" > "$tmp_file.utf8" 2>/dev/null; then
      printf '\xEF\xBB\xBF' > "$tmp_file"
      cat "$tmp_file.utf8" >> "$tmp_file"
      mv "$tmp_file" "$file"
      rm -f "$tmp_file.utf8"
      converted=1
      echo "[CONVERTED] $file (ANSI/GBK -> UTF-8 BOM)"
      break
    fi
  done

  if [[ $converted -eq 0 ]]; then
    rm -f "$tmp_file"
    rm -f "$tmp_file.utf8"
    echo "[SKIP] $file (Unable to decode with supported encodings)"
    continue
  fi
done
