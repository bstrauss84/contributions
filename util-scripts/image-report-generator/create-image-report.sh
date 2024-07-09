#! /bin/bash

set -e

VERSION="${VERSION:-v1}"
DAYS_FILTER=""

# Parse flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --days) DAYS_FILTER="$2"; shift ;;
    -o|--output) output_file="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

if [[ -z "${output_file}" ]]; then
  echo >&2 "usage: create-csv.sh --output <output filename> [--days <number of days>]"
  exit 1
fi

if [[ -z "${ROX_ENDPOINT}" ]]; then
  echo >&2 "ROX_ENDPOINT must be set"
  exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
  echo >&2 "ROX_API_TOKEN must be set"
  exit 1
fi

# Calculate the date based on the number of days ago if specified
if [[ -n "${DAYS_FILTER}" ]]; then
  DATE_THRESHOLD=$(date -u -d "${DAYS_FILTER} days ago" +"%Y-%m-%dT%H:%M:%SZ")
  echo "Filtering images older than ${DAYS_FILTER} days (created before ${DATE_THRESHOLD})"
else
  echo "No filtering applied, listing all images"
fi

# Set the header for the CSV file
if [[ "${VERSION}" == "v1" ]]; then
  echo '"Cluster Name", "Namespace", "Deployment", "Image", "Image Created"' > "${output_file}"
elif [[ "${VERSION}" == "v2" ]]; then
  echo '"Cluster Name", "Cluster Id", "Namespace", "Namespace Id", "Deployment", "Image", "Image Created"' > "${output_file}"
else
  echo "Unknown version ${VERSION} detected. v1 and v2 supported"
  exit 1
fi

function curl_central() {
  curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

# Collect all deployments
res="$(curl_central "v1/deployments")"

# Use a set to store unique entries
declare -A unique_entries

# Iterate over all deployments and get the full deployment details
for deployment_id in $(echo "${res}" | jq -r .deployments[].id); do
  deployment_res="$(curl_central "v1/deployments/${deployment_id}")"
  if [[ "$(echo "${deployment_res}" | jq -rc .name)" == null ]]; then
    continue
  fi

  export deployment_name="$(echo "${deployment_res}" | jq -rc .name)"
  export namespace="$(echo "${deployment_res}" | jq -rc .namespace)"
  export namespaceId="$(echo "${deployment_res}" | jq -rc .namespaceId)"
  export clusterName="$(echo "${deployment_res}" | jq -rc .clusterName)"
  export clusterId="$(echo "${deployment_res}" | jq -rc .clusterId)"

  # Iterate over all images within the deployment and render the CSV lines
  for image_id in $(echo "${deployment_res}" | jq -r 'select(.containers != null) | .containers[].image.id'); do
    if [[ "${image_id}" != "" ]]; then
      image_res="$(curl_central "v1/images/${image_id}" | jq -rc)"
      if [[ "$(echo "${image_res}" | jq -rc .name)" == null ]]; then
        continue
      fi

      image_name="$(echo "${image_res}" | jq -rc '.name.fullName')"
      image_created="$(echo "${image_res}" | jq -rc '.metadata.v1.created')"

      entry_key="${clusterName}|${namespace}|${deployment_name}|${image_name}|${image_created}"

      if [[ -n "${DAYS_FILTER}" ]]; then
        # Apply the date filter
        if [[ "${image_created}" < "${DATE_THRESHOLD}" && -z "${unique_entries[$entry_key]}" ]]; then
          unique_entries[$entry_key]=1

          # Format the CSV correctly based on the version
          if [[ "${VERSION}" == "v1" ]]; then
            echo ""${clusterName}","${namespace}","${deployment_name}","${image_name}","${image_created}"" >> "${output_file}"
          else
            echo ""${clusterName}","${clusterId}","${namespace}","${namespaceId}","${deployment_name}","${image_name}","${image_created}"" >> "${output_file}"
          fi
        fi
      else
        if [[ -z "${unique_entries[$entry_key]}" ]]; then
          unique_entries[$entry_key]=1

          # Format the CSV correctly based on the version
          if [[ "${VERSION}" == "v1" ]]; then
            echo ""${clusterName}","${namespace}","${deployment_name}","${image_name}","${image_created}"" >> "${output_file}"
          else
            echo ""${clusterName}","${clusterId}","${namespace}","${namespaceId}","${deployment_name}","${image_name}","${image_created}"" >> "${output_file}"
          fi
        fi
      fi
    fi
  done
done
