#!/bin/bash
#SBATCH --job-name=sharp_bakta_val
#SBATCH --partition=max50
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/home/ccalomeno/git/sharp-colab/logs/bakta_validation/%x_%j.out
#SBATCH --error=/home/ccalomeno/git/sharp-colab/logs/bakta_validation/%x_%j.err

set -euo pipefail

REPO="/home/ccalomeno/git/sharp-colab"
BAKTA_DB="/scratch/global/databases/bakta/db"

echo "============================================================"
echo "S(H)ARP Bakta DB Slurm validation"
echo "============================================================"
date -Is
hostname
echo "SLURM_JOB_ID=${SLURM_JOB_ID:-none}"
echo "SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK:-none}"

echo
echo "============================================================"
echo "1. Resolve Bakta environment"
echo "============================================================"

BAKTA_ENV="$(
    conda env list 2>/dev/null \
      | awk '$1 == "bakta" {print $NF; exit}'
)"

if [ -z "${BAKTA_ENV:-}" ]; then
    BAKTA_ENV="/home/public/spack/opt/spack/linux-rocky9-zen3/gcc-12.2.0/miniconda3-24.3.0-afr7dkwcon7ppaf4mcdgnje2inigdmrt/envs/bakta"
fi

BAKTA_BIN="$BAKTA_ENV/bin/bakta"
BAKTA_DB_BIN="$BAKTA_ENV/bin/bakta_db"
BAKTA_RUN_PATH="$BAKTA_ENV/bin:$PATH"

echo "BAKTA_ENV=$BAKTA_ENV"
echo "BAKTA_BIN=$BAKTA_BIN"
echo "BAKTA_DB_BIN=$BAKTA_DB_BIN"
echo "BAKTA_DB=$BAKTA_DB"

if [ ! -x "$BAKTA_BIN" ]; then
    echo "ERROR: Bakta executable not found or not executable: $BAKTA_BIN"
    exit 1
fi

if [ ! -d "$BAKTA_DB" ]; then
    echo "ERROR: Bakta DB not found: $BAKTA_DB"
    exit 1
fi

env PATH="$BAKTA_RUN_PATH" "$BAKTA_BIN" --version || true

echo
echo "============================================================"
echo "2. Validate DB metadata"
echo "============================================================"

du -sh "$BAKTA_DB"
ls -lh "$BAKTA_DB/version.json" "$BAKTA_DB/bakta.db"

echo
echo "DB version:"
python -m json.tool "$BAKTA_DB/version.json" || cat "$BAKTA_DB/version.json"

echo
echo "============================================================"
echo "3. Build Bakta validation flags"
echo "============================================================"

BAKTA_HELP="$(env PATH="$BAKTA_RUN_PATH" "$BAKTA_BIN" --help 2>&1 || true)"
BAKTA_SKIP_ARGS=()

add_bakta_flag_if_supported() {
    local FLAG="$1"

    if printf "%s\n" "$BAKTA_HELP" | grep -q -- "$FLAG"; then
        BAKTA_SKIP_ARGS+=("$FLAG")
        echo "Using supported Bakta flag: $FLAG"
    else
        echo "Not supported or absent from help: $FLAG"
    fi
}

# These steps are not required for S(H)ARP CDS/protein validation.
add_bakta_flag_if_supported "--skip-trna"
add_bakta_flag_if_supported "--skip-tmrna"
add_bakta_flag_if_supported "--skip-rrna"
add_bakta_flag_if_supported "--skip-ncrna"
add_bakta_flag_if_supported "--skip-ncrna-region"
add_bakta_flag_if_supported "--skip-crispr"

# Try pseudogene skip flags only if supported by this Bakta version.
add_bakta_flag_if_supported "--skip-pseudo"
add_bakta_flag_if_supported "--skip-pseudogene"
add_bakta_flag_if_supported "--skip-pseudogenes"

echo
echo "Final Bakta validation args:"
if [ "${#BAKTA_SKIP_ARGS[@]}" -eq 0 ]; then
    echo "  none"
else
    printf "  %s\n" "${BAKTA_SKIP_ARGS[@]}"
fi

echo
echo "============================================================"
echo "4. Create small synthetic FASTA"
echo "============================================================"

TEST_DIR="$REPO/examples/bakta_validation"
TEST_FASTA="$TEST_DIR/sharp_bakta_test_genome.fna"
OUT_DIR="$TEST_DIR/bakta_out"

mkdir -p "$TEST_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

python - "$TEST_FASTA" <<'PY'
from pathlib import Path
import sys

out = Path(sys.argv[1])
out.parent.mkdir(parents=True, exist_ok=True)

# Synthetic bacterial-like ORFs for validation only.
orf_a = "ATG" + ("GAC" * 90) + "TAA"
orf_b = "ATG" + ("GCC" * 90) + "TGA"
orf_c = "ATG" + ("ACG" * 90) + "TAG"
orf_d = "ATG" + ("GAA" * 90) + "TAA"
orf_e = "ATG" + ("GGT" * 90) + "TGA"

spacer = "A" * 90

contig_1 = spacer.join([orf_a, orf_b, orf_c, orf_d, orf_e] * 3)
contig_2 = spacer.join([orf_e, orf_d, orf_c, orf_b, orf_a] * 3)

def wrap(seq, width=80):
    return "\n".join(seq[i:i + width] for i in range(0, len(seq), width))

with out.open("w", encoding="utf-8") as handle:
    handle.write(">sharp_test_contig_1\n")
    handle.write(wrap(contig_1) + "\n")
    handle.write(">sharp_test_contig_2\n")
    handle.write(wrap(contig_2) + "\n")
PY

echo "TEST_FASTA=$TEST_FASTA"
ls -lh "$TEST_FASTA"

echo
echo "FASTA validation:"
python - "$TEST_FASTA" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])

headers = 0
sequence_lines = 0
total_bp = 0
bad_lines = []

for line_number, line in enumerate(path.read_text().splitlines(), start=1):
    line = line.strip()

    if not line:
        continue

    if line.startswith(">"):
        headers += 1
        continue

    sequence_lines += 1
    total_bp += len(line)

    if not re.fullmatch(r"[ACGTNacgtn]+", line):
        bad_lines.append((line_number, line[:80]))

print(f"headers={headers}")
print(f"sequence_lines={sequence_lines}")
print(f"total_bp={total_bp}")
print(f"bad_sequence_lines={len(bad_lines)}")

if headers < 1 or sequence_lines < 1 or bad_lines:
    for line_number, preview in bad_lines[:10]:
        print(f"BAD line {line_number}: {preview}")
    raise SystemExit(1)
PY

echo
echo "============================================================"
echo "5. Run Bakta validation"
echo "============================================================"

env PATH="$BAKTA_RUN_PATH" "$BAKTA_BIN" \
  --db "$BAKTA_DB" \
  --output "$OUT_DIR" \
  --prefix sharp_bakta_validation \
  --threads "${SLURM_CPUS_PER_TASK:-4}" \
  --force \
  "${BAKTA_SKIP_ARGS[@]}" \
  "$TEST_FASTA"

echo
echo "============================================================"
echo "6. Check expected Bakta outputs"
echo "============================================================"

EXPECTED_OUTPUTS=(
  "sharp_bakta_validation.gff3"
  "sharp_bakta_validation.gbff"
  "sharp_bakta_validation.faa"
  "sharp_bakta_validation.ffn"
  "sharp_bakta_validation.tsv"
  "sharp_bakta_validation.json"
)

MISSING=0

for FILE in "${EXPECTED_OUTPUTS[@]}"; do
    if [ -s "$OUT_DIR/$FILE" ]; then
        printf "OK      %s\n" "$FILE"
    else
        printf "MISSING %s\n" "$FILE"
        MISSING=1
    fi
done

echo
echo "============================================================"
echo "7. Count CDS/protein outputs"
echo "============================================================"

GFF3="$OUT_DIR/sharp_bakta_validation.gff3"
FAA="$OUT_DIR/sharp_bakta_validation.faa"
FFN="$OUT_DIR/sharp_bakta_validation.ffn"

CDS_COUNT=0
FAA_COUNT=0
FFN_COUNT=0

if [ -s "$GFF3" ]; then
    CDS_COUNT="$(awk '$3 == "CDS" {n++} END {print n+0}' "$GFF3")"
fi

if [ -s "$FAA" ]; then
    FAA_COUNT="$(grep -c '^>' "$FAA" || true)"
fi

if [ -s "$FFN" ]; then
    FFN_COUNT="$(grep -c '^>' "$FFN" || true)"
fi

echo "cds_count=$CDS_COUNT"
echo "faa_records=$FAA_COUNT"
echo "ffn_records=$FFN_COUNT"

if [ "$MISSING" -ne 0 ]; then
    echo
    echo "ERROR: one or more expected Bakta output files are missing."
    exit 1
fi

if [ "$CDS_COUNT" -lt 1 ] || [ "$FAA_COUNT" -lt 1 ] || [ "$FFN_COUNT" -lt 1 ]; then
    echo
    echo "ERROR: Bakta outputs exist, but CDS/protein records are empty."
    exit 1
fi

echo
echo "============================================================"
echo "8. Save validation manifest"
echo "============================================================"

VALIDATION_MANIFEST="$REPO/docs/davinci_bakta_db_validation.txt"
mkdir -p "$(dirname "$VALIDATION_MANIFEST")"

TRNASCAN_BIN="$(env PATH="$BAKTA_RUN_PATH" bash -lc "command -v tRNAscan-SE || true")"
ARAGORN_BIN="$(env PATH="$BAKTA_RUN_PATH" bash -lc "command -v aragorn || true")"
CMSCAN_BIN="$(env PATH="$BAKTA_RUN_PATH" bash -lc "command -v cmscan || true")"
PILERCR_BIN="$(env PATH="$BAKTA_RUN_PATH" bash -lc "command -v pilercr || true")"

{
    echo "created_at=$(date -Is)"
    echo "host=$(hostname)"
    echo "slurm_job_id=${SLURM_JOB_ID:-}"
    echo "slurm_cpus_per_task=${SLURM_CPUS_PER_TASK:-}"
    echo "bakta_env=$BAKTA_ENV"
    echo "bakta_bin=$BAKTA_BIN"
    echo "bakta_db_bin=$BAKTA_DB_BIN"
    echo "bakta_version=$(env PATH="$BAKTA_RUN_PATH" "$BAKTA_BIN" --version 2>&1 | head -1 || true)"
    echo "bakta_db=$BAKTA_DB"
    echo "bakta_db_size=$(du -sh "$BAKTA_DB" | awk '{print $1}')"
    echo "bakta_db_version_json=$BAKTA_DB/version.json"
    echo "trnascan_bin=${TRNASCAN_BIN:-}"
    echo "aragorn_bin=${ARAGORN_BIN:-}"
    echo "cmscan_bin=${CMSCAN_BIN:-}"
    echo "pilercr_bin=${PILERCR_BIN:-}"
    echo "bakta_validation_args=${BAKTA_SKIP_ARGS[*]:-}"
    echo "test_fasta=$TEST_FASTA"
    echo "test_output_dir=$OUT_DIR"
    echo "gff3=$OUT_DIR/sharp_bakta_validation.gff3"
    echo "gbff=$OUT_DIR/sharp_bakta_validation.gbff"
    echo "faa=$OUT_DIR/sharp_bakta_validation.faa"
    echo "ffn=$OUT_DIR/sharp_bakta_validation.ffn"
    echo "tsv=$OUT_DIR/sharp_bakta_validation.tsv"
    echo "json=$OUT_DIR/sharp_bakta_validation.json"
    echo "cds_count=$CDS_COUNT"
    echo "faa_records=$FAA_COUNT"
    echo "ffn_records=$FFN_COUNT"
    echo "validation=PASS"
} | tee "$VALIDATION_MANIFEST"

echo
echo "============================================================"
echo "Validation PASS"
echo "============================================================"
date -Is
