# S(H)ARP public resource inventory

This document records the public resources bundled with the S(H)ARP Colab repository.

## Motif resource

- `resources/motifs/heptarepeats2.meme`
- Original development source: Haldane `/home/leep/epsoares/projects/igem/2026/data/heptarepeats2.meme`
- Used by FIMO to detect heptamer repeat / regulatory motif evidence.

## SARP HMM resource

- `resources/hmm/sarp_custom.hmm`
- Original development source: Haldane `/home/leep/epsoares/projects/igem/2026/data/btad_sarp.v2.hmm`
- Used by `hmmsearch` to detect SARP/BtaD-like regulator evidence.

## Domain model resource

- `resources/domain_models/domain_models.hmm`
- Original development source: Haldane `/home/leep/epsoares/projects/igem/2026/data/all_models.hmm`
- Used by `hmmscan` to annotate domain evidence in candidate neighborhoods.
- HMMER pressed files are not versioned by default; the notebook can generate them with `hmmpress`.

## Optional model name map

- `resources/domain_models/hmm_modelnames.tsv`
- Original development source: Haldane `/home/leep/epsoares/projects/igem/2026/data/hmm_modelnames.tsv`
- Optional mapping table for interpreting domain model names when available.

## Still missing

- `resources/embeddings/reference_embeddings.parquet`
- Required for embedding-based evidence and final complete scoring.
