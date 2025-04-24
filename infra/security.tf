# Configuración de recursos de seguridad en AWS
# Este archivo define los recursos de seguridad como GuardDuty y CloudTrail

# Habilitar GuardDuty para detección de amenazas
# GuardDuty es un servicio de detección de amenazas inteligente
resource "aws_guardduty_detector" "gd" {
  enable = true
}

# Configurar CloudTrail para registro de auditoría
# CloudTrail registra todas las acciones realizadas en la cuenta de AWS
resource "aws_cloudtrail" "trail" {
  name                          = "wiz-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}

# VULNERABILIDAD: No se configura encriptación para los logs de CloudTrail
# VULNERABILIDAD: No se configura retención de logs
# VULNERABILIDAD: No se configura notificación de eventos de seguridad
