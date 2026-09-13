"""Fail CI when the PostgreSQL/Testcontainers release gates did not execute."""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


REQUIRED_TEST_CLASSES = (
    "com.fittrack.database.FlywayPostgresMigrationTest",
    "com.fittrack.database.PostgresApplicationContextTest",
)


def main() -> int:
    report_dir = Path("target/surefire-reports")
    problems: list[str] = []

    for class_name in REQUIRED_TEST_CLASSES:
        report = report_dir / f"TEST-{class_name}.xml"
        if not report.is_file():
            problems.append(f"missing report: {report}")
            continue

        suite = ET.parse(report).getroot()
        tests = int(suite.attrib.get("tests", "0"))
        skipped = int(suite.attrib.get("skipped", "0"))
        failures = int(suite.attrib.get("failures", "0"))
        errors = int(suite.attrib.get("errors", "0"))
        if tests == 0 or skipped > 0 or failures > 0 or errors > 0:
            problems.append(
                f"{class_name}: tests={tests}, skipped={skipped}, "
                f"failures={failures}, errors={errors}"
            )

    if problems:
        print("PostgreSQL release gate failed:", file=sys.stderr)
        for problem in problems:
            print(f"- {problem}", file=sys.stderr)
        return 1

    print("PostgreSQL release gate passed: both Testcontainers suites executed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
