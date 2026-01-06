#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
PURPLE="\e[35m"
BOLD="\e[1m"
GREY="\e[90m"
ENDCOLOR="\e[0m"

FECHA=$(date +'%Y-%m-%d_%H-%M')

log_action() {
    echo -e "${GREY}[DEBUG][$(date +'%H:%M:%S')] $1${ENDCOLOR}"
}

check_deps() {
    echo -e "\n${BLUE}[*] Verificando herramientas instaladas...${ENDCOLOR}"
    tools=("nmap" "whois" "dig" "nikto" "whatweb" "gobuster" "wafw00f")
    missing=()

    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}[!] Atención: Faltan herramientas: ${RED}${missing[*]}${ENDCOLOR}"
        read -p " ¿Deseas que MultiScan las instale por ti? (s/n): " choice
        if [[ "$choice" =~ ^[Ss]$ ]]; then
            log_action "Actualizando sistema e instalando: ${missing[*]}"
            sudo apt update
            for m_tool in "${missing[@]}"; do
                # Mapeo: 'dig' está en el paquete dnsutils
                [ "$m_tool" == "dig" ] && sudo apt install dnsutils -y || sudo apt install $m_tool -y
            done
            echo -e "${GREEN}[✔] Herramientas instaladas correctamente.${ENDCOLOR}"
        else
            echo -e "${RED}[!] Advertencia: Algunas funciones podrían fallar sin estas herramientas.${ENDCOLOR}"
            sleep 2
        fi
    else
        echo -e "${GREEN}[✔] Entorno preparado: Todas las dependencias están OK.${ENDCOLOR}"
    fi
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

set_target() {
    [ -z "$TARGET" ] && read -p " [+] Introduce la URL/IP objetivo: " TARGET
    CLEAN_TARGET=$(echo $TARGET | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    ROOT_DIR="Escaneos/$CLEAN_TARGET/$FECHA"
    RAW_DIR="$ROOT_DIR/raw_logs"
    mkdir -p "$RAW_DIR"
}

pasivo() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO RECONOCIMIENTO PASIVO${ENDCOLOR}"
    log_action "Consultando WHOIS y DNS..."
    whois "$CLEAN_TARGET" | tee "$RAW_DIR/whois.txt"
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    dig "$CLEAN_TARGET" ANY | tee "$RAW_DIR/dns.txt"
    host -t mx "$CLEAN_TARGET" | tee -a "$RAW_DIR/dns.txt"
    echo -e "\n${GREEN}[✔] Fase pasiva finalizada.${ENDCOLOR}"
}

red() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO ESCANEO DE RED (NMAP)${ENDCOLOR}"
    log_action "Comando: nmap -sV -sC -O -T4 $CLEAN_TARGET"
    sudo nmap -sV -sC -O -T4 "$CLEAN_TARGET" -vvv | tee "$RAW_DIR/nmap.txt"
    echo -e "\n${GREEN}[✔] Fase de red finalizada.${ENDCOLOR}"
}

web() {
    echo -e "\n${YELLOW}${BOLD}[>>>] INICIANDO ANÁLISIS WEB${ENDCOLOR}"
    log_action "Identificando Firewall y Stack Tecnológico..."
    wafw00f "$TARGET" | tee "$RAW_DIR/waf.txt"
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    whatweb "$TARGET" -v | tee "$RAW_DIR/tecnologias.txt"
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    nikto -h "$TARGET" | tee "$RAW_DIR/nikto.txt"
    echo -e "\n${CYAN}--------------------------------------------------${ENDCOLOR}"
    WORDLIST="/usr/share/wordlists/dirb/common.txt"
    if [ -f "$WORDLIST" ]; then
        gobuster dir -u "https://$CLEAN_TARGET" -w "$WORDLIST" -b "301,404" --no-progress -a "Mozilla/5.0" | tee "$RAW_DIR/gobuster.txt"
    else
        log_action "Advertencia: No se encontró wordlist estándar en /usr/share/wordlists/dirb/common.txt"
    fi
    echo -e "\n${GREEN}[✔] Fase web finalizada.${ENDCOLOR}"
}

generar_reporte() {
    REPORT_FILE="$ROOT_DIR/REPORTE_FINAL.md"
    log_action "Sintetizando información en $REPORT_FILE..."
    {
        echo "# INFORME TÉCNICO DE SEGURIDAD - $CLEAN_TARGET"
        echo "Fecha: $(date)"
        echo "--------------------------------------------------"
        echo "## 1. RECONOCIMIENTO DE DOMINIO"
        [ -f "$RAW_DIR/dns.txt" ] && grep "IN NS" "$RAW_DIR/dns.txt" | awk '{print "* Servidor NS: " $5}' || echo "* No se realizaron pruebas DNS."
        
        echo -e "\n## 2. SERVICIOS Y PUERTOS (RESUMEN)"
        [ -f "$RAW_DIR/nmap.txt" ] && grep "open" "$RAW_DIR/nmap.txt" | sed 's/^/| /' || echo "* Escaneo de red no realizado."
        
        echo -e "\n## 3. SEGURIDAD WEB"
        [ -f "$RAW_DIR/waf.txt" ] && grep "WAF" "$RAW_DIR/waf.txt" | sed 's/^/* /'
        [ -f "$RAW_DIR/nikto.txt" ] && grep "+" "$RAW_DIR/nikto.txt" | head -n 10 | sed 's/^/* /' || echo "* Auditoría web no realizada."
    } > "$REPORT_FILE"
    echo -e "\n${PURPLE}${BOLD}[!!!] REPORTE PROFESIONAL DISPONIBLE EN: $REPORT_FILE${ENDCOLOR}"
}

banner
check_deps
set_target

while true; do
    banner
    echo -e "${CYAN}Objetivo Actual:${ENDCOLOR} $TARGET | ${CYAN}Ruta:${ENDCOLOR} $ROOT_DIR"
    echo -e "--------------------------------------------------------"
    echo -e " ${BLUE}0)${ENDCOLOR} ${YELLOW}Reinstalar/Chequear herramientas${ENDCOLOR}"
    echo -e " ${BLUE}1)${ENDCOLOR} Lanzar Fase Pasiva"
    echo -e " ${BLUE}2)${ENDCOLOR} Lanzar Escaneo de Red"
    echo -e " ${BLUE}3)${ENDCOLOR} Lanzar Análisis Web"
    echo -e " ${BLUE}4)${ENDCOLOR} ${BOLD}FULL AUDIT (Fases 1,2,3 + Reporte)${ENDCOLOR}"
    echo -e " ${BLUE}5)${ENDCOLOR} Cambiar Objetivo"
    echo -e " ${BLUE}6)${ENDCOLOR} Salir"
    echo -e "--------------------------------------------------------"
    read -p " Selección: " opt

    case $opt in
        0) check_deps ;;
        1) pasivo ;;
        2) red ;;
        3) web ;;
        4) pasivo; red; web; generar_reporte ;;
        5) exec "$0" ;;
        6) log_action "Finalizando."; exit 0 ;;
        *) echo "Inválido." ;;
    esac
    echo -e "\n${YELLOW}Pulsa ENTER...${ENDCOLOR}"; read
done
