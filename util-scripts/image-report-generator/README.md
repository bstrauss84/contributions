# Image Report Generator

This script generates a CSV report of container images used in deployments. The report can include either all images or only those older than a specified number of days.

## Usage

### Generating the Full List of Images

To generate a CSV report with all images:

```bash
./create-image-report.sh --output output.csv
```

### Generating the Filtered List of Images (Older than a Specified Number of Days)

To generate a CSV report with images older than a specified number of days (e.g., 90 days):

```bash
./create-image-report.sh --output output.csv --days 90
```

## Parameters

- `--output <output filename>`: Specifies the name of the output CSV file.
- `--days <number of days>`: Optional flag to filter images older than the specified number of days.

## Prerequisites

- The script requires the `ROX_ENDPOINT` and `ROX_API_TOKEN` environment variables to be set.

```bash
export ROX_ENDPOINT=<your_rox_endpoint>
export ROX_API_TOKEN=<your_rox_api_token>
```

## Example

```bash
export ROX_ENDPOINT="central.example.com"
export ROX_API_TOKEN="your_api_token"

# Generate a full image report
./create-image-report.sh --output full_image_report.csv

# Generate a filtered image report (older than 90 days)
./create-image-report.sh --output filtered_image_report.csv --days 90
```

## Notes

- Ensure that you have the necessary permissions to access the StackRox API.
- The script supports two versions of the CSV format, which can be configured using the `VERSION` environment variable.
  - `v1` (default): Includes `Cluster Name`, `Namespace`, `Deployment`, `Image`, and `Image Created` fields.
  - `v2`: Includes additional fields `Cluster Id` and `Namespace Id`.
