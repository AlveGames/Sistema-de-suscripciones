import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv("SECRET_KEY", "clave-solo-para-desarrollo-cambiar")
DEBUG = os.getenv("DEBUG", "1") == "1"
ALLOWED_HOSTS = ["127.0.0.1", "localhost"]

INSTALLED_APPS = [
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "core",           # Eyser: modelos, plantilla base, inicio
    "categorias",     # Eyser: MOLDE
    "clientes",       # Nevarez
    "servicios",      # Castañeda
    "catalogos",      # Jorge Jaime
    "uso",            # Rommel
    "suscripciones",  # Eyser
    "consultas",      # Joel Lino
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "plataforma.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "plataforma.wsgi.application"

# SQL Server. Si DB_USER está vacío, usa autenticación de Windows.
DATABASES = {
    "default": {
        "ENGINE": "mssql",
        "NAME": os.getenv("DB_NAME", "PlataformaSuscripciones"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", ""),
        "USER": os.getenv("DB_USER", ""),
        "PASSWORD": os.getenv("DB_PASSWORD", ""),
        "OPTIONS": {
            "driver": os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server"),
            "extra_params": "TrustServerCertificate=yes",
        },
    }
}

# Mensajes de éxito/error en una cookie: así Django no necesita tablas propias.
MESSAGE_STORAGE = "django.contrib.messages.storage.cookie.CookieStorage"

LANGUAGE_CODE = "es"
TIME_ZONE = "America/Guayaquil"
USE_I18N = True
USE_TZ = False

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.AutoField"