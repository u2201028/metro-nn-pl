# Data and evaluation protocol (roadmap Phase 2)

## Labeling protocol

1. **Define visible fighting and relevant normal activities before
   labeling.**  The label taxonomy and the difficult-negative list are
   fixed in the labeling protocol before any annotator sees test data:
   difficult negatives include crowd surges, running, hugging, boarding
   and camera shake.
2. **Deduplicate before sampling.**  Duplicate (camera, source, time-span)
   records are rejected by `data/split_manifest.py::duplication_check`
   before any window is sampled.
3. **Group before splitting.**  Original videos, related clips and cameras
   are grouped by `group_key`; a group never appears on two sides of a
   split (`validate_split` enforces this).
4. **Fix operating thresholds on validation data.**  The operating point is
   locked on validation only; the test set is unblinded once.

## Metrics protocol

Reported for the locked operating point, per camera/site stratum:

- precision, recall and F1 at clip level,
- event recall and event delay (alert time minus event onset),
- false alerts per negative camera-hour, with total negative camera-hours
  published alongside counts by camera,
- sample counts and camera/site breakdowns.

## Split protocol

- Splits are versioned (`SplitManifest.schema_version = 1`) and written
  with `write_manifest`.
- Groups (original videos, related clips, cameras) never span split sides;
  `validate_split` rejects any split that divides a group.
- Duplication checks run before sampling; duplicates are rejected, not
  silently merged.
- Uncertain camera provenance is kept in a separate evaluation stratum.

## Sampling protocol

- The analysis rate is 25 analyzed frames/s for one stream (Section 1).
- A source that only supplies 20 FPS is reported with its observed rate and
  replayed at an independently paced 25 Hz to isolate accelerator capacity;
  its frames are never silently resampled into the 25 Hz stream.
- Timebase, FPS, decoder, transport, jitter buffer and rights to use the
  footage are recorded per clip in the split manifest.
