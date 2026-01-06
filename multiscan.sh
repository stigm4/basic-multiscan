#!/bin/bash

# --- COLORES PARA IDENTIFICACIÓN ---
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
PURPLE="\e[35m"
BOLD="\e[1m"
GREY="\e[90m"
ENDCOLOR="\e[0m"

# --- CONFIGURACIÓN DE SELLO DE TIEMPO ---
FECHA=$(date +'%Y-%m-%d_%H-%M')

# --- FUNCIÓN DE LOG INTERNO (VERBOSE) ---
log_action() {
    echo -e "${GREY}[DEBUG][$(date +'%H:%M:%S')] $1${ENDCOLOR}"
}

banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "                           ░██    ░██    ░██                                            "
    echo "                           ░██    ░██                                                   "
    echo "░█████████████  ░██    ░██ ░██ ░████████ ░██ ░███████   ░███████   ░██████   ░████████  "
    echo "░██   ░██   ░██ ░██    ░██ ░██    ░██    ░██░██        ░██    ░██       ░██  ░██    ░██ "
    echo "░██   ░██   ░██ ░██    ░██ ░██    ░██    ░██ ░███████  ░██         ░███████  ░██    ░██ "
    echo "░██   ░██   ░██ ░██   ░███ ░██    ░██    ░██       ░██ ░██    ░██ ░██   ░██  ░██    ░██ "
    echo "░██   ░██   ░██  ░█████░██ ░██     ░████ ░██ ░███████   ░███████   ░█████░██ ░██    ░██ "
    echo "    v:Basic                                                            +report    v1.0b "
    echo "                                                                       por  :  estigma"
    echo -e "${ENDCOLOR}"
}

# --- CONFIGURACIÓN INICIAL ---
log_action "Iniciando proceso de configuración..."
read -p " [+] Introduce la URL/IP objetivo: " TARGET

if [ -z "$TARGET" ]; then 
    echo -e "${RED}Error: Objetivo vacío.${ENDCOLOR}"; exit 1
fi

log_action "Limpiando nombre del objetivo..."
CLEAN_TARGET=$(echo $TARGET | sed -e 's|^[^/]*//||' -e 's|/.*$||')

log_action "Creando estructura de directorios..."
ROOT_DIR="Escaneos/$CLEAN_TARGET/$FECHA"
RAW_DIR="$ROOT_DIR/raw_logs"
mkdir -p "$RAW_DIR"
log_action "Directorios creados en: $ROOT_DIR"

# --- FUNCIONES DE ESCANEO CON SALIDA REALTIME ---

pasivo() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO RECONOCIMIENTO PASIVO${ENDCOLOR}"
    
    log_action "Ejecutando WHOIS sobre $CLEAN_TARGET..."
    whois "$CLEAN_TARGET" | tee "$RAW_DIR/whois.txt"
    
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    log_action "Consultando registros DNS (DIG)..."
    dig "$CLEAN_TARGET" ANY | tee "$RAW_DIR/dns.txt"
    
    log_action "Buscando registros MX (Correo)..."
    host -t mx "$CLEAN_TARGET" | tee -a "$RAW_DIR/dns.txt"
    
    echo -e "\n${GREEN}[✔] Fase pasiva finalizada.${ENDCOLOR}"
}

red() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO ESCANEO DE RED (NMAP)$${ENDCOLOR}"
    log_action "Comando: nmap -sV -sC -O -T4 $CLEAN_TARGET -vvv"
    
    # Usamos sudo para nmap por la detección de SO
    sudo nmap -sV -sC -O -T4 "$CLEAN_TARGET" -vvv | tee "$RAW_DIR/nmap.txt"
    
    echo -e "\n${GREEN}[✔] Fase de red finalizada.${ENDCOLOR}"
}

web() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO ANÁLISIS WEB${ENDCOLOR}"
    
    log_action "Identificando Firewall (WAFW00F)..."
    wafw00f "$TARGET" | tee "$RAW_DIR/waf.txt"
    
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    log_action "Escaneando tecnologías con WhatWeb..."
    whatweb "$TARGET" -v | tee "$RAW_DIR/tecnologias.txt"
    
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    log_action "Iniciando Nikto (Escaneo de vulnerabilidades web)..."
    nikto -h "$TARGET" | tee "$RAW_DIR/nikto.txt"
    
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    log_action "Buscando directorios ocultos con Gobuster..."
    WORDLIST="/usr/share/wordlists/dirb/common.txt"
    
    if [ -f "$WORDLIST" ]; then
        # quitamos -q para que hable
        # añadimos --no-progress para que sea compatible con archivos de texto
        # mantenemos el -b 301,404 para evitar que se detenga
        
        gobuster dir -u "https://$CLEAN_TARGET" \
                     -w "$WORDLIST" \
                     -b "301,404" \
                     --no-progress \
                     -a "Mozilla/5.0 (X11; Ubuntu; Linux x86_64)" | tee "$RAW_DIR/gobuster.txt"
    else
        log_action "Error: Wordlist no encontrada."
    fi
    
    echo -e "\n${GREEN}[✔] Fase web finalizada.${ENDCOLOR}"
}

generar_reporte() {
    REPORT_FILE="$ROOT_DIR/REPORTE_FINAL.md"
    log_action "Compilando información para el reporte en: $REPORT_FILE"
    
    {
        echo "# INFORME TÉCNICO DE SEGURIDAD - $CLEAN_TARGET"
        echo "Generado el: $(date)"
        echo "--------------------------------------------------"
        echo "## 1. RESULTADOS DNS Y DOMINIO"
        grep "IN NS" "$RAW_DIR/dns.txt" | awk '{print "* Servidor NS: " $5}'
        echo "## 2. PUERTOS Y SERVICIOS DETECTADOS"
        grep "open" "$RAW_DIR/nmap.txt" | sed 's/^/| /'
        echo "## 3. SEGURIDAD WEB"
        grep "WAF" "$RAW_DIR/waf.txt" | sed 's/^/* /'
        echo "## 4. HALLAZGOS NIKTO"
        grep "+" "$RAW_DIR/nikto.txt" | sed 's/^/* /'
    } > "$REPORT_FILE"
    
    echo -e "\n${PURPLE}${BOLD}[!!!] REPORTE PROFESIONAL GENERADO EN: $REPORT_FILE${ENDCOLOR}"
}

# --- BUCLE DEL MENÚ ---
while true; do
    banner
    echo -e "${CYAN}Objetivo:${ENDCOLOR} $TARGET | ${CYAN}Logs:${ENDCOLOR} $ROOT_DIR"
    echo -e "--------------------------------------------------------"
    echo -e " ${BLUE}1)${ENDCOLOR} Lanzar Reconocimiento Pasivo (Verbose)"
    echo -e " ${BLUE}2)${ENDCOLOR} Lanzar Escaneo de Red (Verbose)"
    echo -e " ${BLUE}3)${ENDCOLOR} Lanzar Análisis Web (Verbose)"
    echo -e " ${BLUE}4)${ENDCOLOR} ${BOLD}FULL AUDIT (Todas las fases + Reporte)${ENDCOLOR}"
    echo -e " ${BLUE}5)${ENDCOLOR} Cambiar Objetivo"
    echo -e " ${BLUE}6)${ENDCOLOR} Salir"
    echo -e "--------------------------------------------------------"
    read -p "Seleccione opción: " opt

    case $opt in
        1) pasivo ;;
        2) red ;;
        3) web ;;
        4) log_action "Iniciando Auditoría Completa..."; pasivo; red; web; generar_reporte ;;
        5) exec "$0" ;; # Reinicia el script
        6) log_action "Cerrando script..."; exit 0 ;;
        *) echo "Opción no válida" ;;
    esac
    
    echo -e "\n${YELLOW}Proceso terminado. Presiona ENTER para continuar...${ENDCOLOR}"
    read
done
