"""Verify that a hosted-agent interaction is retrievable from Application Insights.

Run after deploying main.bicep, deploying the agent in ./agent, and assigning the agent identity
Monitoring Metrics Publisher (assign_agent_identity_role.py).

It sends a prompt containing a unique marker to the agent through the project Responses API, then
polls Application Insights (REST, Entra ID token) for dependency spans carrying that response id.
Reading as the signed-in user needs Log Analytics Reader on the component; to prove the project
managed identity can read, rerun with the project identity's credentials.

Usage:
    python verify_traces.py --project-endpoint https://<acct>.services.ai.azure.com/api/projects/<proj> \
        --agent-name hosted-agent --app-id <applicationInsightsAppId>
"""

import argparse
import sys
import time
import uuid

import requests
from azure.identity import DefaultAzureCredential

QUERY_URL = "https://api.applicationinsights.io/v1/apps/{app_id}/query"
KQL = """
dependencies
| where timestamp > ago(30m)
| where tostring(customDimensions['gen_ai.input.messages']) contains '{marker}'
| project timestamp, name, success, operation_Id, cloud_RoleName,
          response_id = tostring(customDimensions['gen_ai.response.id']),
          agent = tostring(customDimensions['gen_ai.agent.name'])
| order by timestamp asc
"""


def invoke_agent(credential, project_endpoint: str, agent_name: str, prompt: str) -> str:
    token = credential.get_token("https://ai.azure.com/.default").token
    resp = requests.post(
        f"{project_endpoint}/agents/{agent_name}/endpoint/protocols/openai/responses",
        params={"api-version": "v1"},
        headers={"Authorization": f"Bearer {token}"},
        json={"input": prompt},
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()["id"]


def query_traces(credential, app_id: str, marker: str) -> list:
    token = credential.get_token("https://api.applicationinsights.io/.default").token
    resp = requests.post(
        QUERY_URL.format(app_id=app_id),
        headers={"Authorization": f"Bearer {token}"},
        json={"query": KQL.format(marker=marker)},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["tables"][0]["rows"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-endpoint", required=True)
    parser.add_argument("--agent-name", required=True)
    parser.add_argument("--app-id", required=True, help="Application Insights AppId")
    parser.add_argument("--timeout-minutes", type=int, default=10)
    args = parser.parse_args()

    credential = DefaultAzureCredential()
    marker = f"trace-check-{uuid.uuid4().hex[:8]}"
    response_id = invoke_agent(credential, args.project_endpoint, args.agent_name, f"Say hello. {marker}")
    print(f"invoked agent, response id {response_id}, marker {marker}")

    deadline = time.time() + args.timeout_minutes * 60
    while time.time() < deadline:
        rows = query_traces(credential, args.app_id, marker)
        if rows:
            print(f"PASS: found {len(rows)} span(s) for marker {marker}")
            for row in rows:
                print("  ", row)
            return 0
        print("no spans yet, waiting 30s (ingestion can take a few minutes)")
        time.sleep(30)

    print(f"FAIL: no spans for marker {marker} within {args.timeout_minutes} minutes")
    return 1


if __name__ == "__main__":
    sys.exit(main())
