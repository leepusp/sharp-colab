# S(H)ARP Bakta DB light cache

This repository does not store the Bakta database in git.

For public Colab genome-only validation, S(H)ARP uses a GitHub Release asset:

- Release tag: `bakta-db-light-v6.0`
- Asset: `db-light.tar.xz`
- Public URL: `https://github.com/leepusp/sharp-colab/releases/download/bakta-db-light-v6.0/db-light.tar.xz`
- Source: Zenodo record `14916843`
- DOI: `10.5281/zenodo.14916843`
- MD5: `4a6e059ded39e9c5537ef4137d2f5648`
- SHA256: `dab28b58fbf51fde4b72793c1edf7a9de6530cfb501d2dd5a72b16b8ecb4c705`

The intended Colab behavior is:

1. Download `db-light.tar.xz` from the GitHub Release asset.
2. Validate checksum.
3. Extract the database into local `/content`.
4. Run Bakta against the extracted local database.
5. Do not run Bakta directly from Google Drive or from a compressed archive.

For the current validation phase, Prodigal fallback is disabled. Genome-only input should use the cached Bakta DB light backend.
