resource "aws_s3_bucket" "b" {
  bucket = "puneet_bucket"  
  tags = {
    Name        = "My bucket"
  }  
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}
