# S(H)ARP — Streptomyces Hidden Antibiotic Regulated Pathways

## Run in Google Colab

Open the public S(H)ARP notebook directly in Google Colab:

[![Open S(H)ARP in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/leepusp/sharp-colab/blob/main/notebooks/sharp_public_colab.ipynb)

The notebook loads public S(H)ARP resources from this GitHub repository and writes a complete HTML/ZIP results package at the end of the run.

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
