library(dplyr)
.b = import('../../base')
.io = import('../../io')
.ar = import('../../array')
.guess_id_type = import('./guess_id_type')$guess_id_type

#' Gene ID mapping function
#'
#' @param obj   a character vector or named object to be mapped
#' @param from  the type of ids to map from; if NULL will try regex matching
#'              this can be: 'hgnc_symbol', 'entrezgene', 'ensembl_gene_id',
#'              'band', 'chromosome_name', 'transcript_start', 'transcript_end',
#'              'transcription_start_site'
#' @param to    the type of ids to map to (same types as for 'from')
#' @param dset  Ensembl data set, e.g. '{hsapiens,mmusculus}_gene_ensembl'
#' @param summarize  the function to use to aggregate ids
#' @return      the mapped and optionally summarized object
gene = function(obj, from=NULL, to, dset="hsapiens_gene_ensembl", summarize=mean) {
    UseMethod("gene")
}

gene.character = function(obj, to, from=.guess_id_type(obj),
                          dset="hsapiens_gene_ensembl", summarize=mean) {
    if (to %in% c("hgnc_symbol", "mgi_symbol"))
        to = "external_gene_name"

    lookup = gene_table(dset)
    df = na.omit(data.frame(from=lookup[[from]], to=lookup[[to]]))
    df = df[!duplicated(df),]
    .b$match(obj, from=df$from, to=df$to)
}

gene.default = function(obj, to, from=.guess_id_type(.ar$dimnames(obj, along=1)),
                        dset="hsapiens_gene_ensembl", summarize=mean) {
    if (to %in% c("hgnc_symbol", "mgi_symbol"))
        to = "external_gene_name"

    lookup = gene_table(dset)
    df = na.omit(data.frame(from=lookup[[from]], to=lookup[[to]]))
    df = df[!duplicated(df),]

    # remove versions of gene ids
    if (from == "ensembl_gene_id") {
        if (is.array(obj))
            dimnames(obj)[[1]] = sub("\\.[0-9]+$", "", dimnames(obj)[[1]])
        else
            names(obj) = sub("\\.[0-9]+$", "", dimnames(obj)[[1]])
    }

    .ar$summarize(obj, along=1, from=df$from, to=df$to, FUN=summarize)
}

gene.ExpressionSet = function(obj, to, from=.guess_id_type(rownames(exprs(obj))),
                              dset="hsapiens_gene_ensembl", summarize=mean) {
    exprs(obj) = gene(Biobase::exprs(obj), from=from, to=to, dset=dset, summarize=summarize)
    obj
}

gene.list = function(obj, to, from, dset="hsapiens_gene_ensembl", summarize=mean) {
    lapply(obj, gene, to=to, from=from, dset=dset, summarize=summarize)
}

#' Creates a table of different identifiers and caches it
#'
#' @param force  Re-generate table if it already exists
#' @return       A data.frame with the following columns:
#'     hgnc_symbol, affy, illumina, genbank, entrezgeen, ensembl_gene_id
gene_table = function(dset="hsapiens_gene_ensembl", force=FALSE) {
    fname = sprintf("gene_table-%s.RData", dset)
    cache = file.path(module_file(), "cache", fname)
    if (file.exists(cache) && !force)
        return(.io$load(cache))

    mart = biomaRt::useMart(biomart="ensembl", dataset=dset)
    ids = c('external_gene_name', 'entrezgene', 'ensembl_gene_id',
            'band', 'chromosome_name',
            'transcript_start', 'transcript_end', 'transcription_start_site')
    mapping = biomaRt::getBM(attributes=ids, mart=mart)
    for (col in colnames(mapping)) {
        mapping[[col]] = as.character(mapping[[col]])
        is_empty = nchar(mapping[,col]) == 0
        mapping[[col]][is_empty] = NA
    }

    dir.create(dirname(cache), showWarnings=FALSE)
    save(mapping, file=cache)
    mapping
}

if (is.null(module_name())) {
    library(testthat)

    re = gene("10009", to="hgnc_symbol")
    expect_equal("ZBTB33", unname(re))
}
