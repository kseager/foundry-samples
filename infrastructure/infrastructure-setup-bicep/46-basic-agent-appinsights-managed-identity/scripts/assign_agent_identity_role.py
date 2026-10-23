"""Grant a hosted agent's identity Monitoring Metrics Publisher on Application Insights.

Agent identities do not exist at deployment time, so this runs after the agent is created. The
role lets the agent write traces to a component with local (key) auth disabled.

Usage:
    python assign_agent_identity_role.py --app-insights-id <resource id> --principal-id <agent identity object id>
"""

import argparse
import subprocess
import sys

MONITORING_METRICS_PUBLISHER = "3913510d-42f4-4e42-8a64-420c390055eb"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-insights-id", required=True)
    parser.add_argument("--principal-id", required=True, help="Object ID of the agent identity")
    args = parser.parse_args()

    result = subprocess.run(
        [
            "az", "role", "assignment", "create",
            "--assignee-object-id", args.principal_id,
            "--assignee-principal-type", "ServicePrincipal",
            "--role", MONITORING_METRICS_PUBLISHER,
            "--scope", args.app_insights_id,
        ],
        shell=sys.platform == "win32",
    )
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
