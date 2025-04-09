#!/bin/bash

# Create APOLOS sourced.

home_dir="$HOME"
file=".apolo"
FILES="$home_dir/$file"
bin_="$PREFIX/bin"
export_dir="$bin_/exporto"

# Create apolo

cat << 'EOF' > "$FILES"

#!/bin/bash

## Coded by Noba ##

## DIRECTORY CONFIG

actual_dir=$(pwd)
bin_d="$PREFIX/bin"
bin_usr="$PREFIX/usr"
bin_opt="$PREFIX/opt"

## --

## BANNER


banner() {
  echo "      ___            __           ";
  echo "     /   |  ____  __/ /____  _____"; 
  echo "    / /| | / __ \/ __/ ___/ / ___/";
  echo "   / ___ |/ / / / /_/ /__  (__  ) ";
  echo "  /_/  |_/_/ /_/\__/\___/ /____/  ";
  echo "            APOLO SYSTEM          ";
}


##\\

## Save PS1


ps1_s="$PS1"


## --



shopt -s expand_aliases



## ALIAS //

alias 'shw'="echo"
alias '::'="#"

#\\

shf() {
  if declare -f "$1" > /dev/null; then
    declare -f "$1"
  else
    echo "[!] Función '$1' no encontrada"
  fi
}



alias 'try.ext'="shf" # El alias esta aqui para no tener problemas declarando con shf 

traps() {

  trap
  set -euo pipefail
  trap 'echo "Error en la línea $LINENO"' ERR

}

run_cpp() {
    local id="$1"
    local code=$(awk -v id="##CPP_END id=\"$id\"" '
        $0 ~ /##CPP_BEGIN/ {found=1; next}
        found && $0 ~ id {found=0; exit}
        found {print}
    ' "$0")

    # Si querés compilar en RAM, usamos /dev/shm
    gcc -x c -o /dev/shm/c_exec - <<< "$code" && /dev/shm/c_exec
    rm /dev/shm/c_exec
}


run() {
   case "$1" in
     --python)
	     python $2
	  ;;
	 --bash) 
	     bash $2
    ;;
   -cpp)
    local id="$1"
    local code=$(awk -v id="##CPP_END id=\"$id\"" '
        $0 ~ /?CPP_BEGIN/ {found=1; next}
        found && $0 ~ id {found=0; exit}
        found {print}
    ' "$0")

    # Si querés compilar en RAM, usamos /dev/shm
    gcc -x c -o /dev/shm/c_exec - <<< "$code" && /dev/shm/c_exec
    rm /dev/shm/c_exec
   ;;
   -py)
    local id="$1"
    local code=$(awk -v id="##PY_END id=\"$id\"" '
        $0 ~ /##PY_BEGIN/ {found=1; next}
        found && $0 ~ id {found=0; exit}
        found {print}
    ' "$0")

    python3 - <<< "$code"
	 ;;
	 *)
	   eval "$@"
	 ;;
   esac
}

1usx() {
  echo "/dev/ttyUSB$1"
}

send_cmd() {
  local mensaje="$1"
  local dispositivo="$2"
  echo "$mensaje" > "$dispositivo"
}

# example: send_cmd "CMD:REBOOT" "$(usx 0)"

try() {
  case "$1" in
    -err)
      shift
      if ! "$@"; then
        return 1
      else
        return 0
      fi
      ;;
    *)
      "$@"
      ;;
  esac
}

check() {
  case "$1" in
    -apt)
      if apt list --installed 2>/dev/null | grep -q "$2"; then
        return 1
      else
        return 0
      fi
      ;;
    -dpkg)
      if dpkg --list | grep -q "$2"; then
        return 1
      else
        return 0
      fi
      ;;
    *)
      "$@"
      ;;
  esac
}





# Code blocks


:: C++

# DECLARE FUNC

setter() {
  case "$1" in
    -cpp)
      local id="${2:-main1}"
      parse_cpp_blocks
      echo "${CPP_CODES[$id]}"
      gcc -x c - <<< "${CPP_CODES[$id]}" -o "$id" && ./"$id"
      ;;
    *)
      shw "[ERR]: Usage= set -cpp [id]"
      ;;
  esac
}




declare -A CPP_CODES  # Diccionario ID => código

parse_cpp_blocks() {
    local self_file="${BASH_SOURCE[0]}"
    local inside=0 code="" id=""

    while IFS= read -r line; do
        if [[ "$line" == "?CPP_BEGIN" ]]; then
            inside=1
            code=""
            continue
        elif [[ "$line" =~ \?CPP_END\ id=\"(.*)\" ]]; then
            inside=0
            id="${BASH_REMATCH[1]}"
            CPP_CODES["$id"]="$code"
            echo "[+] Código guardado como ID '$id'"
        elif [[ $inside -eq 1 ]]; then
            code+="$line"$'\n'
        fi
    done < "$self_file"
}

save() {
  parse_cpp_blocks  # Asegura que se carguen los bloques

  case "$1" in
    --dialog)
      shift
      if [[ "$1" != "-cpp" ]]; then
        echo "[ERR] Sólo se soporta --dialog con -cpp por ahora"
        return 1
      fi

      local id="$2"
      local temp_cpp="temp_${id}.cpp"
      local output="./out_${id}"

      if [[ -z "${CPP_CODES[$id]+x}" ]]; then
        echo "[ERR] No se encontró código con ID '$id'"
        return 1
      fi

      echo "${CPP_CODES[$id]}" > "$temp_cpp"

      echo "[*] Compilando '$id'..."
      if g++ "$temp_cpp" -o "$output"; then
        echo "[+] Compilado exitosamente. Ejecutando..."
        "$output"
      else
        echo "[ERR] Falló la compilación"
        return 1
      fi

      # Opcional: borrar archivos si no los querés
      rm -f "$temp_cpp" "$output"
      ;;
    
    -cpp)
      local id="$2"
      local archivo="$3"

      if [[ -z "${CPP_CODES[$id]+x}" ]]; then
        echo "[ERR] No se encontró código con ID '$id'"
        return 1
      fi

      echo "${CPP_CODES[$id]}" > "$archivo"
      echo "[+] Código '$id' guardado en '$archivo'"
      ;;
    
    *)
      echo "[ERR] Uso:"
      echo "    save -cpp <id> <archivo.cpp>       # Guardar código a archivo"
      echo "    save --dialog -cpp <id>            # Guardar, compilar y ejecutar"
      ;;
  esac
}


### DECRYPT

export() {
  case "$1" in
    --encrypted)
      local out="$2"
      local key="ApoloSecretKey123"
      local content=$(<"${BASH_SOURCE[0]}")
      local enc=$(echo "$content" | openssl enc -aes-256-cbc -a -salt -pass pass:"$key")
      cat <<SET > "$out"
#!/bin/bash
key="$key"
decrypt() {
  echo "\$1" | base64 -d | openssl enc -aes-256-cbc -d -pass pass:"\$key" 2>/dev/null
}
payload="$enc"
eval "\$(decrypt \"\$payload\")"
SET
      chmod +x "$out"
      echo "[+] Script exportado como '$out'"
      ;;
    *)
      echo "[!] Uso: export_apolo --encrypted salida.sh"
      ;;
  esac
}


EOF



cat <<'EOF' > "$export_dir"

export() {
  case "$1" in
    --encrypted)
      local out="$2"
      local key="ApoloSecretKey123"
      local content=$(<"${BASH_SOURCE[0]}")
      local enc=$(echo "$content" | openssl enc -aes-256-cbc -a -salt -pass pass:"$key")
      cat <<SET > "$out"
#!/bin/bash
key="$key"
decrypt() {
  echo "\$1" | base64 -d | openssl enc -aes-256-cbc -d -pass pass:"\$key" 2>/dev/null
}
payload="$enc"
eval "\$(decrypt \"\$payload\")"
SET
      chmod +x "$out"
      echo "[+] Script exportado como '$out'"
      ;;
    *)
      echo "[!] Uso: export_apolo --encrypted salida.sh"
      ;;
  esac
}

EOF