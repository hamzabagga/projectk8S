
# Approach #2: Use environment variables to set credentials
provider "aws" {
  region = "us-east-1"
}

# Approach 3: Use a shared credentials file
# This file is typically located at ~/.aws/credentials on Unix-like systems or C:\Users\USERNAME\.aws\credentials on Windows.
#
#  provider "aws" {
#     region = "us-east-1"
#     shared_credentials_file = "/path/to/aws_credentials"
# }
