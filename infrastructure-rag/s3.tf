resource "aws_s3_bucket" "documents" {
  bucket = "hackaton-data-animal-shelter"
}

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = "${aws_s3_bucket.documents.id}"
    lambda_function {
      lambda_function_arn = "${aws_lambda_function.hackaton_rag_upload.arn}"
      events              = ["s3:ObjectCreated:*"]
    }
}

resource "aws_lambda_permission" "aws-lambda-trigger-permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hackaton_rag_upload.function_name}"
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${aws_s3_bucket.documents.id}"
}