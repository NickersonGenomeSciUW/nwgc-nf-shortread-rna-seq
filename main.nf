include { STAR_MAP_MERGE_SORT } from './workflows/star_map_merge_sort.nf'
include { ANALYSIS } from './workflows/analysis.nf'

workflow {

    // Versions channel
    ch_versions = Channel.empty()
    ch_analysisInput = Channel.empty()

    // Fastqs channel
    ch_fastqs =
        Channel.from(params.fastqs)
            .map{ row ->
                String fastq1Files = row.fastq1Files
                String fastq2Files = row.fastq2Files
                String readGroups = row.readGroups

                return tuple(fastq1Files, fastq2Files, readGroups)
            }

    // Map/Merge using STAR
    STAR_MAP_MERGE_SORT(ch_fastqs)
    ch_versions = ch_versions.mix(STAR_MAP_MERGE_SORT.out.versions)

    // Verify read count is high enough to proceed
    read_count_ch = STAR_MAP_MERGE_SORT.out.analysisTuple
      .branch {starBam, starBai, transcriptomeBam, junctionsTab, readCount ->
            pass: readCount.isInteger() && readCount.toInteger() >= 1000
            fail: !readCount.isInteger() || readCount.toInteger() < 1000
      }

    // If not enough reads, write early exit message to stdout
    read_count_ch.fail.view()

    // Analysis input channel
    ch_analysisInput = read_count_ch.pass
    if (!params.fastqs && params.analysis) {
        ch_analysisInput =
            Channel.from(params.analysis)
                .map{ row ->
                    Path starBam = file(row.starBam)
                    Path starBai = file(row.starBam + ".bai")
                    Path transcriptomeBam = file(row.transcriptomeBam)
                    Path spliceJunctionsTab = file(row.spliceJunctionsTab)

                    return tuple(starBam, starBai, transcriptomeBam, spliceJunctionsTab)
                }
    }

    // Analysis
    ANALYSIS(ch_analysisInput)
    ch_versions = ch_versions.mix(ANALYSIS.out.versions)

    ch_versions.unique().collectFile(name: 'rna-star_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}
