# Preston DwC-A Interactions 

This script uses [`preston`]() and [`elton`]() to extract biotic interaction from DwC-Archives in the biodiversity dataset graph.

# Usage


```
./preston-dwca-interactions.sh -c path/to/data-dir
```

**Options**:
 - `-c`: path to `data-dir` (`preston` cache directory will be localted at `<data-dir>/biodata`)
 - `-r`(optional): if set, the script will use a remote data directory (`http://deeplinker.bio`), otherwise it will use the local cache at `<data-dir>/biodata`

# Interaction types mapping

The `conf` directory contains two `csv` files:
- `interaction_types_mapping.csv`: mapping file between unrecognized interaction types to terms in Relation Ontology (regonized by `elton`);
- `interaction_types_ignored.csv`: list of interaction types to be ignored by `elton`;

To retrieve a up-to-date list of mappings and ignored interaction types you may run the `update.sh` script:
```bash
./update.sh
```

It will retrieve the interaction types from a spreadsheet at [https://docs.google.com/spreadsheets/u/0/d/1gNVEiN5GJxrei6QwgqC_sbvKzaJrktm_Pv1Psqx2GtI](https://docs.google.com/spreadsheets/u/0/d/1gNVEiN5GJxrei6QwgqC_sbvKzaJrktm_Pv1Psqx2GtI).


# Output

The script will download (if necessary) all DwC-A in the current biodiversity dataset graph and extract interaction records using `elton` to the file `<data-dir>/interactions.tsv` and the reviews report produced by `elton` to `<data-dir>/reviews.txt`.





