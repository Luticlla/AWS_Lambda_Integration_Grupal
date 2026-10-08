resource "aws_s3_bucket_notification" "images_to_sqs" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.s3_to_sqs]

  # El filtro uploads/ es imprescindible: sin él, processed/ también dispararía
  # este evento y la cola entraría en un bucle infinito de recorte y costos.
}
