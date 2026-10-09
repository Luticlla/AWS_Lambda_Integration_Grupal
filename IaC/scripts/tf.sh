#!/usr/bin/env bash
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-customprofile}"

usage() {
  echo "Uso: bash scripts/tf.sh <entorno> <comando> [argumentos de Terraform]"
  echo
  echo "Entornos:"
  echo "  dev"
  echo "  qa"
  echo "  prod"
  echo
  echo "Ejemplos:"
  echo "  bash scripts/tf.sh dev plan"
  echo "  bash scripts/tf.sh qa plan"
  echo "  bash scripts/tf.sh prod apply"
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

ENVIRONMENT="$1"
COMMAND="$2"
shift 2

if [[ -z "${TF_STATE_BUCKET:-}" ]]; then
  echo "ERROR: Debes definir la variable de entorno TF_STATE_BUCKET."
  echo "Ejemplo:"
  echo "  export TF_STATE_BUCKET=<bucket-del-estado>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${IAC_DIR}"

BACKEND_FILE=""
TFVARS_FILE=""

case "$ENVIRONMENT" in
  dev)
    BACKEND_FILE="backend/dev.hcl"
    TFVARS_FILE="environments/dev.tfvars"
    ;;

  qa)
    BACKEND_FILE="backend/qa.hcl"
    TFVARS_FILE="environments/qa.tfvars"
    ;;

  prod)
    BACKEND_FILE="backend/prod.hcl"
    TFVARS_FILE="environments/prod.tfvars"
    ;;

  *)
    echo "ERROR: Entorno no válido: $ENVIRONMENT"
    echo "Valores permitidos: dev, qa, prod"
    exit 1
    ;;
esac

echo "=========================================="
echo " Terraform - Image Processor"
echo "=========================================="
echo "Entorno:      $ENVIRONMENT"
echo "Variables:    $TFVARS_FILE"
echo "Backend:      $BACKEND_FILE"
echo "=========================================="

if [[ ! -f "$BACKEND_FILE" ]]; then
  echo "ERROR: No existe el backend: $BACKEND_FILE"
  exit 1
fi

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "ERROR: No existe el archivo de variables: $TFVARS_FILE"
  exit 1
fi

if [[ "$COMMAND" == "plan" || "$COMMAND" == "apply" || "$COMMAND" == "destroy" ]]; then

  if [[ -f "lambdas/upload/build.sh" && ! -d "lambdas/upload/build" ]]; then
    echo "ERROR: Falta construir upload-lambda."
    echo "Ejecuta lambdas/upload/build.sh antes de continuar."
    exit 1
  fi

  if [[ -f "lambdas/crop/build.sh" && ! -d "lambdas/crop/build" ]]; then
    echo "ERROR: Falta construir crop-lambda."
    echo "Ejecuta lambdas/crop/build.sh antes de continuar."
    exit 1
  fi

fi

if [[ "$ENVIRONMENT" == "prod" && "$COMMAND" == "destroy" ]]; then

  echo
  echo "ADVERTENCIA: estás intentando destruir PROD."
  echo

  read -r -p "Para confirmar escribe exactamente 'destruir prod': " CONFIRM

  if [[ "$CONFIRM" != "destruir prod" ]]; then
    echo "Operación cancelada."
    exit 1
  fi

fi

echo
echo "Inicializando Terraform..."

terraform init \
  -reconfigure \
  -input=false \
  -backend-config="$BACKEND_FILE" \
  -backend-config="bucket=$TF_STATE_BUCKET"

echo
echo "Ejecutando: terraform $COMMAND"

case "$COMMAND" in
  plan|apply|destroy|import|refresh|console)
    terraform "$COMMAND" \
      -var-file="$TFVARS_FILE" \
      "$@"
    ;;

  *)
    terraform "$COMMAND" \
      "$@"
    ;;
esac
