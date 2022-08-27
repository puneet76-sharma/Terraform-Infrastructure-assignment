resource "aws_cloudfront_distribution" "s3_distribution" {
  web_acl_id = aws_wafv2_web_acl.WAF.arn
  
  origin {
    domain_name = aws_s3_bucket.b.website_endpoint
    origin_id   = "s3"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  origin {
    domain_name = aws_lb.applications_load_balancer.dns_name
    origin_id   = "Loadbalancer"

	custom_origin_config {
		http_port              = 80
		https_port             = 443
		origin_protocol_policy = "http-only"
		origin_ssl_protocols   = ["TLSv1.2"]
	
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Terraform"

  ordered_cache_behavior {
    path_pattern     = "index.html"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "Loadbalancer"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "allow-all"
  }


  price_class = "PriceClass_200"
  viewer_certificate {
    cloudfront_default_certificate = true 
    }
    restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}