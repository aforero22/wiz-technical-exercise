# Configuración de recursos de seguridad en AWS
# Este archivo define los recursos de seguridad como GuardDuty y CloudTrail

# Security controls - AWS GuardDuty for threat detection
data "aws_guardduty_detector" "existing" {
  id = "default"
}

resource "aws_guardduty_detector" "gd" {
  count   = data.aws_guardduty_detector.existing.id == "" ? 1 : 0
  enable  = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
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
