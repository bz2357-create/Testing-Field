"""Independent standard-library audit of R exports against original CSV files.
Run after rendering: python3 tests/verify_outputs.py
"""
import csv
import datetime as dt
import math
import statistics as stats
from collections import defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[1]
expected = {}
for year, expected_days in [(2018, 361), (2019, 365), (2020, 121)]:
    with (root / f'data/AQ_{year}.csv').open() as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        columns = reader.fieldnames
    groups = defaultdict(lambda: [[], [], []])
    seen = set()
    for row in rows:
        key = tuple(row.items())
        if key in seen:
            continue
        seen.add(key)
        day = dt.datetime.strptime(row['Date'], '%m/%d/%Y').date()
        for j, col in enumerate([columns[1], columns[3], columns[5]]):
            if row[col] not in ('', 'NA'):
                groups[day][j].append(max(float(row[col]), 0))
    assert len(groups) == expected_days
    for day, measures in groups.items():
        expected[day.isoformat()] = [stats.mean(v) if v else None for v in measures]

with (root / 'output/daily_air_quality.csv').open() as f:
    actual = list(csv.DictReader(f))
assert len(actual) == len(expected) == 847
assert len({r['date'] for r in actual}) == 847
for row in actual:
    for col, want in zip(('co', 'pm25', 'o3'), expected[row['date']]):
        if want is None:
            assert row[col] == ''
        else:
            assert math.isclose(float(row[col]), want, abs_tol=1e-12)

with (root / 'output/monthly_pooled_summary.csv').open() as f:
    for row in csv.DictReader(f):
        j = ('co', 'pm25', 'o3').index(row['pollutant'])
        vals = [v[j] for day, v in expected.items()
                if int(day[5:7]) == int(row['month']) and v[j] is not None]
        mean, sd = stats.mean(vals), stats.stdev(vals)
        assert int(row['n']) == len(vals)
        for col, want in [('mean', mean), ('sd', sd),
                          ('lower', mean - 1.96 * sd / math.sqrt(len(vals))),
                          ('upper', mean + 1.96 * sd / math.sqrt(len(vals)))]:
            assert math.isclose(float(row[col]), want, abs_tol=1e-12)
with (root / 'output/annual_ranges.csv').open() as f:
    for row in csv.DictReader(f):
        j = ('co', 'pm25', 'o3').index(row['pollutant'])
        vals = [v[j] for day, v in expected.items()
                if day.startswith(row['year']) and v[j] is not None]
        assert int(row['n']) == len(vals)
        assert math.isclose(float(row['minimum']), min(vals), abs_tol=1e-12)
        assert math.isclose(float(row['maximum']), max(vals), abs_tol=1e-12)
with (root / 'output/pm25_monthly_by_year.csv').open() as f:
    rows = list(csv.DictReader(f))
assert len(rows) == 28
for row in rows:
    vals = [v[1] for day, v in expected.items() if day.startswith(row['year'])
            and int(day[5:7]) == int(row['month']) and v[1] is not None]
    assert int(row['n']) == len(vals)
    assert math.isclose(float(row['pm25']), stats.mean(vals), abs_tol=1e-12)
print('Independent audit passed: 847 daily records, annual ranges, monthly means, sample sizes, and 95% CIs.')
