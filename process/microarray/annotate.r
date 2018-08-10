#' Mapping of annotation identifier to annotation package
#'
#' there should be a mapping between the two available somewhere?
#' List of BioC annots: https://www.bioconductor.org/packages/3.3/data/annotation/
mapping = list(
    "pd.hg.u95a" = "hgu95a.db",
    "pd.hg.u95b" = "hgu95b.db",
    "pd.hg.u95av2" = "hgu95av2.db", # A-AFFY-1, GPL8300
    "hgu133a" = "hgu133a.db", # A-GEOD-14668
    "pd.hg.u133a" = "hgu133a.db", # A-AFFY-33, GPL96
    "pd.hg.u133b" = "hgu133b.db", # A-AFFY-34, GPL97
    "pd.hg.u133.plus.2" = "hgu133plus2.db", # A-AFFY-44, GPL570
    "pd.hg.u133a.2" = "hgu133a2.db", # A-AFFY-37, GPL571
    "pd.hg.u219" = "hgu219.db", # A-GEOD-13667, GPL13667
    "pd.hugene.1.0.st.v1" = "hugene10sttranscriptcluster.db", # A-AFFY-141, GPL6244
    "pd.hugene.1.0.st.v1" = "hugene10sttranscriptcluster.db",
    "pd.hugene.1.1.st.v1" = "hugene11sttranscriptcluster.db",
    "pd.hugene.2.0.st" = "hugene20sttranscriptcluster.db",
    "pd.hugene.2.1.st" = "hugene21sttranscriptcluster.db",
    "pd.huex.1.0.st.v1" = "huex10sttranscriptcluster.db", # A-AFFY-143
    "pd.huex.1.0.st.v2" = "huex10sttranscriptcluster.db",
    "pd.ht.hg.u133a" = "hthgu133a.db", # A-AFFY-76
#    "pd.ht.hg.u133.plus.pm" = ???,
    "pd.hta.2.0" = "hta20transcriptcluster.db",
    "u133aaofav2" = "hthgu133a.db" # needs to be manually processed by affy
)

#' Function to annotate expression objects
#'
#' @param normData   A normalized data object, or a list thereof
#' @param summarize  IDs to annotate with: hgnc_symbol
#' @return           The annotated data
annotate = function(normData, summarize="hgnc_symbol", ...) {
    UseMethod("annotate")
}

annotate.list = function(normData, summarize="hgnc_symbol") {
    re = lapply(normData, function(x) annotate(x) %catch% NA)
    if (any(is.na(re)))
        warning("dropping ", names(re)[is.na(re)])
    if (all(is.na(re)))
        stop("all annotations failed")
    re[!is.na(re)]
}

annotate.ExpressionSet = function(normData, summarize="hgnc_symbol") {
    annotation = mapping[[normData@annotation]]
    if (is.null(annotation))
        stop("No annotation package found for: ", normData@annotation)

    # read metadata and replace matrix by annotated matrix
    emat = annotate(as.matrix(exprs(normData)),
                    annotation = annotation,
                    summarize = summarize)

    Biobase::ExpressionSet(assayData = emat,
                           phenoData = phenoData(normData))
}

annotate.NChannelSet = function(normData, summarize="hgnc_symbol") {
    if (! "E" %in% ls(assayData(normData)))
        stop("only single-channel implemented atm")

    # note: there are agilent annotation packages available, but the
    # array ID is not saved in normData@annotation
	map_channel = function(expr, ids, from="agilent", to=summarize) {
		rownames(expr) = ids
		idmap$probeset(expr, from=from, to=summarize)
	}
    idmap = import('../idmap')
    ad = as.list(Biobase::assayData(normData))
	mapped = sapply(ad, map_channel, ids=fData(normData)$ProbeName,
                    simplify=FALSE, USE.NAMES=TRUE)

    es = ExpressionSet(mapped$E)
    phenoData(es) = phenoData(normData)
    es
}

annotate.matrix = function(normData, annotation, summarize="hgnc_symbol") {
    # load annotation package
    if (!require(annotation, character.only=TRUE)) {
        source("http://bioconductor.org/biocLite.R")
        biocLite(annotation)
        library(annotation, character.only=TRUE)
    }

    # work on expression matrix, summarize using limma
    if (summarize == "hgnc_symbol")
        rownames(normData) = annotate::getSYMBOL(as.vector(rownames(normData)), annotation)
    else if (summarize == "entrezgene")
        rownames(normData) = annotate::getEG(as.vector(rownames(normData)), annotation)
    else
        stop("Method", summarize, "not supported, only 'hgnc_symbol', 'entrezgene'")
    limma::avereps(normData[!is.na(rownames(normData)),])
}
