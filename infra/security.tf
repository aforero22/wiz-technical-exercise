# Configuración de recursos de seguridad en AWS
# Este archivo define los recursos de seguridad como GuardDuty y CloudTrail

# Security controls - AWS GuardDuty for threat detection
# Verificar si ya existe un detector de GuardDuty en la cuenta
data "aws_guardduty_detector" "existing" {
  id = "default"  # El detector por defecto siempre tiene el ID "default"
}

# Crear un nuevo detector solo si no existe uno
resource "aws_guardduty_detector" "gd" {
  count   = data.aws_guardduty_detector.existing.id == "" ? 1 : 0  # Crear solo si no existe
  enable  = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"  # Frecuencia de publicación de hallazgos
}

# Configurar CloudTrail para registro de auditoría
# CloudTrail registra todas las acciones realizadas en la cuenta de AWS
resource "aws_cloudtrail" "trail" {
  name                          = "wiz-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

# VULNERABILIDAD: No se configura encriptación para los logs de CloudTrail
# VULNERABILIDAD: No se configura retención de logs
# VULNERABILIDAD: No se configura notificación de eventos de seguridad
