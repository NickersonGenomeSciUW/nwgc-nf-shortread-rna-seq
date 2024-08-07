include { DEEPTOOLS_BAM_COVERAGE as COVERAGE_BY_CHROMOSOME } from '../../modules/analysis/deeptools_bam_coverage_by_chromosome.nf'
include { DEEPTOOLS_BAM_COVERAGE as COVERAGE_BY_SAMPLE } from '../../modules/analysis/deeptools_bam_coverage_by_sample.nf'

workflow BIGWIG {

    take:
        markedDupsBamTuple
        bigWigDirectory
        sampleInfoTuple
        organism
        effectiveGenomeSize

    main:

        ch_versions = Channel.empty()

        if (organism.equals("Homo sapiens")) {
            // Chromsomee-Strand Input for DEEPTOOLS_BAM_COVERAGE
            chromosomesChannel = Channel.fromList(params.chromosomes)
            strandChannel = Channel.fromList(['forward','reverse'])
            chromosomeStrandTuple = chromosomesChannel.combine(strandChannel)
            deeptoolsInputTuple = chromosomeStrandTuple.combine(markedDupsBamTuple).combine(bigWigDirectory).combine(sampleInfoTuple)

            COVERAGE_BY_CHROMOSOME(deeptoolsInputTuple, effectiveGenomeSize)
            ch_versions = ch_versions.mix(COVERAGE_BY_CHROMOSOME.out.versions)
        }
        else {
            strandChannel = Channel.fromList(['forward','reverse'])
            deeptoolsInputTuple = strandChannel.combine(markedDupsBamTuple).combine(bigWigDirectory).combine(sampleInfoTuple)

            COVERAGE_BY_SAMPLE(deeptoolsInputTuple, effectiveGenomeSize)
            ch_versions = ch_versions.mix(COVERAGE_BY_SAMPLE.out.versions)
        }

    emit:
        versions = ch_versions

}
