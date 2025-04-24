 # GuardDuty habilitado (detectivo)
resource "aws_guardduty_detector" "gd" {
  enable = true
}

# CloudTrail (audit logging)
resource "aws_cloudtrail" "trail" {
  name                          = "wiz-trail"
  s3_bucket_name                = aws_s3_bucket.backups.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
}