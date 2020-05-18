# S3-scraping
AWS S3 scraping scripts

s3_listing.sh takes the URL of an s3 bucket as its only argument, dumps a listing of the bucket where each line includes the following 3 elements delimited with spaces:

    timestamp file_size path/to/file with spaces

s3_mirror.sh requires 2 arguments:

 - the path to an S3 bucket
 - a local destination path

Where the local file exists, but is the wrong size, it copies the file from the S3 bucket to the local destination.

If `-d` is passed as the first argument, it prints the file sizes it would otherwise attempt to download.
