import os
import mysql.connector

def get_connection():
    parametres = dict(
        host=os.environ.get("DB_HOST", "localhost"),
        port=int(os.environ.get("DB_PORT", 3306)),
        user=os.environ.get("DB_USER", "root"),
        password=os.environ.get("DB_PASSWORD", "M0tdep@sse"),
        database=os.environ.get("DB_NAME", "gestion_colis"),
        charset='utf8mb4',
        collation='utf8mb4_unicode_ci',
        use_pure=True
    )
    chemin_certificat = os.environ.get("DB_SSL_CA")
    if chemin_certificat:
        parametres["ssl_ca"] = chemin_certificat
        parametres["ssl_verify_cert"] = True
    return mysql.connector.connect(**parametres)
