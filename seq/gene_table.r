#' Creates a table of different identifiers and caches it
#'
#' @param dset  Ensembl data set, e.g. '{hsapiens,mmusculus}_gene_ensembl'
#' @param version   Ensembl version (integer)
#' @param assembly  Genome assembly version (allowed: "GRCh37", "GRCh38")
#' @param force  Re-generate table if it already exists
#' @return       A data.frame with gene and transcript-level information
gene_table = function(dset="hsapiens_gene_ensembl", version="latest",
                      assembly="GRCh38", force=FALSE) {
    printv = function(dset) message(sprintf("Using Ensembl %s (%s)",
        attr(dset, "ensembl_version"), attr(dset, "dataset_version")))

    grch = as.integer(sub("[^0-9]+([0-9]+)$", "\\1", assembly))
    if (version == "latest")
        version = 103 #TODO: get this + be robust offline

    fname = sprintf("gene_table-%s-ens%i-%i.rds", dset, version, grch)
    cache = file.path(module_file(), "cache", fname)
    if (file.exists(cache) && !force) {
        mapping = readRDS(cache)
        printv(mapping)
        return(mapping)
    }

    grch2 = grch
    if (grch == 38)
        grch2 = NULL # they don't allow to specify GRCh38 explicitly
    ensembl = biomaRt::useEnsembl("ensembl", dataset=dset, GRCh=grch2)
    marts = biomaRt::listMarts(ensembl)
    vstring = marts$version[marts$biomart == "ENSEMBL_MART_ENSEMBL"]
    version = as.integer(sub(".* ([0-9]+)$", "\\1", vstring))
    datasets = biomaRt::listDatasets(ensembl, version)
    dataset_version = datasets$version[datasets$dataset == dset]

    # if biomart has newer ensembl update cache file name
    fname = sprintf("gene_table-%s-ens%s-%i.rds", dset, version, grch)
    cache = file.path(module_file(), "cache", fname)
    message("Generating cache file ", sQuote(fname))

    ids = c('external_gene_name', 'entrezgene_id', 'ensembl_gene_id',
            'band', 'chromosome_name', 'start_position', 'end_position',
            'ensembl_transcript_id', 'transcript_start', 'transcript_end',
            'transcription_start_site', 'strand', 'gene_biotype')
    mapping = tibble::as_tibble(biomaRt::getBM(attributes=ids, mart=ensembl))
    for (col in colnames(mapping)) {
        is_empty = nchar(as.character(mapping[,col])) == 0
        mapping[[col]][is_empty] = NA
    }

    attr(mapping, "ensembl_version") = version
    attr(mapping, "dataset_version") = dataset_version

    dir.create(dirname(cache), showWarnings=FALSE)
    saveRDS(mapping, file=cache)
    printv(mapping)
    mapping
}

if (is.null(module_name())) {
    gene_table("hsapiens_gene_ensembl")
    gene_table("mmusculus_gene_ensembl")
}
