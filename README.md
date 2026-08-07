# S(H)ARP — Streptomyces Hidden Antibiotic Regulated Pathways

S(H)ARP is a Colab-oriented workflow developed by iGEM USP-Brazil 2026 for detecting candidate regulatory regions associated with biosynthetic gene clusters in Streptomyces genomes.

## Public workflow

The user provides one of the following inputs:

1. Genome FASTA only
2. Genome FASTA + GFF3/GenBank annotation + protein FASTA
3. ZIP/TAR package containing the files above

Internal S(H)ARP resources are bundled in this repository and loaded automatically by the Colab notebook.

## Internal resources

Expected resource layout:

    resources/
    ├── motifs/
    │   └── heptarepeats2.meme
    ├── hmm/
    │   └── sarp_custom.hmm
    ├── domain_models/
    │   └── domain_models.hmm
    ├── embeddings/
    │   └── reference_embeddings.parquet
    ├── config/
    │   └── sharp_scoring_config.json
    └── modules/
        └── operon_fig_colab.py

## Colab resource base URL

Once published, the notebook should load bundled resources from:

    https://raw.githubusercontent.com/leepusp/sharp-colab/main/resources

## Current status

Development version: 0.1.0-dev.
