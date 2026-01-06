# 🛡️ MultiScan v1.0b - Suite Automatizada de Reconocimiento y Auditoría

**MultiScan** es una herramienta desarrollada en Bash diseñada para optimizar las fases de recolección de información (*Recon*) y análisis de vulnerabilidades. Su objetivo es centralizar múltiples herramientas de seguridad líderes en la industria bajo una sola interfaz robusta, proporcionando una salida de datos en tiempo real (Verbose) y reportes organizados.

Desarrollado por: **estigma** ⚡

## 🚀 Características

El script integra flujos de trabajo profesionales divididos en tres pilares fundamentales:

### 1. Inteligencia Pasiva (OSINT)
*   **WHOIS:** Extracción de datos de registro de dominio y propiedad.
*   **Análisis DNS:** Consulta de registros A, MX y NS mediante `dig` y `host` para identificar la infraestructura del servidor y gestión de correos.

### 2. Auditoría de Infraestructura y Red
*   **Análisis con Nmap:** Escaneo detallado de puertos, detección de servicios, versiones y *fingerprinting* de Sistema Operativo.
*   **Optimización de Tiempos:** Configuración T4 para un escaneo eficiente sin comprometer la precisión del análisis.

### 3. Seguridad de Aplicaciones Web
*   **Detección de Firewalls (WAF):** Identificación de protecciones activas con `wafw00f`.
*   **Fingerprinting Tecnológico:** Análisis detallado de servicios web y stacks de software con `WhatWeb`.
*   **Escaneo de Vulnerabilidades:** Implementación de `Nikto` para detectar archivos sensibles y configuraciones inseguras.
*   **Fuzzing de Directorios:** Integración con `Gobuster`, optimizado para evadir bloqueos por redirección (301) y detección de wildcards, operando con cabeceras de navegador reales.

## 📂 Gestión y Organización de Hallazgos

MultiScan está diseñado para mantener un orden riguroso, vital en entornos profesionales de consultoría. Cada análisis genera una jerarquía de directorios basada en el objetivo y el tiempo de ejecución:

```text
Escaneos/
└── [dominio_objetivo]/
    └── [AAAA-MM-DD_HH-MM]/
        ├── REPORTE_FINAL.md     <-- Documento de síntesis ejecutiva
        └── raw_logs/            <-- Registro íntegro de herramientas
            ├── nmap.txt
            ├── nikto.txt
            ├── gobuster.txt
            └── dns.txt
```

## 📋 Requisitos

Asegúrese de contar con las siguientes herramientas en su entorno (Recomendado: Kali Linux / Parrot Security OS):

Comando de instalación de dependencias:
```bash
sudo apt update && sudo apt install nmap whois dnsutils nikto whatweb gobuster wafw00f -y
```

### Configuración inicial
1.- Clone el repositorio
```bash
git clone https://github.com/tu-usuario/multiscan.git
cd multiscan
```

2.- Asigne permisos de ejecución del script:
```bash
chmod +x multiscan.sh
```

## 🛠️ Uso
```bash
sudo ./multiscan.sh
```

## 📑 Reporte y Feedback en Tiempo Real
A diferencia de procesos automatizados silenciosos, MultiScan utiliza una arquitectura de tuberías (Verbose Mode) que permite al auditor visualizar cada línea de comando ejecutada en pantalla mientras los datos se indexan simultáneamente en los archivos de log. El reporte final consolida los hallazgos críticos en formato Markdown para facilitar su edición y presentación.

## ⚠️ Descargo de Responsabilidad (Disclaimer)
Esta herramienta ha sido creada con fines estrictamente educativos y para su uso en entornos controlados bajo consentimiento mutuo. El autor no asume responsabilidad por el uso inadecuado o ataques no autorizados realizados con este software. Actúe siempre dentro del marco legal vigente.

    
---
---
