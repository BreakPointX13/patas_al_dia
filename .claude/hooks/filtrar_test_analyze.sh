#!/bin/bash
# Hook PostToolUse: filtra el output de "flutter test" y "flutter analyze"
# para que solo lleguen al contexto de Claude las lineas relevantes
# (errores, fallos, warnings) en vez del log completo.
set -euo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<< "$input")

# Solo actuar sobre flutter test / flutter analyze; cualquier otro comando
# Bash pasa sin modificar.
if [[ "$command" != *"flutter test"* && "$command" != *"flutter analyze"* ]]; then
  exit 0
fi

text=$(jq -r '.tool_response.text // empty' <<< "$input")

if [[ -z "$text" ]]; then
  exit 0
fi

total_lines=$(wc -l <<< "$text")

filtered=$(grep -iE 'error|fail|warning|issue|exception|no issues found|all tests passed' <<< "$text" || true)

if [[ -z "$filtered" ]]; then
  filtered=$(tail -n 5 <<< "$text")
fi

kept_lines=$(wc -l <<< "$filtered")

if [[ "$kept_lines" -ge "$total_lines" ]]; then
  # No hay nada que ahorrar, dejar pasar el output original
  exit 0
fi

resumen="[Output filtrado por hook: $kept_lines de $total_lines lineas mostradas]"
resultado="${resumen}"$'\n\n'"${filtered}"

jq -n --arg text "$resultado" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedToolOutput: $text
  }
}'
