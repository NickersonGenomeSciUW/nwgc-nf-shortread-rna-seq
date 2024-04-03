process FASTX_QC {

    tag "FASTX_QC_${sampleId}_${userId}"

    publishDir "${fastxQCDirectory}", mode:  'link', pattern: "*.fastq.stats"
 
    input:
        path fastq
        val fastxQCDirectory
        tuple val(sampleId), val(publishDirectory), val(userId)

    output:
        env FASTQ_BASENAME, emit: fastqBasename
        path "*.fastq.stats",  emit: stats
        path "versions.yaml", emit: versions

    script:
        """
        FASTQ_BASENAME=\$(basename "$fastq" .fastq.gz)

        gunzip -c $fastq | \
        fastx_quality_stats \
            -Q 33 \
            -o \${fastqName}.fastq.stats.temp

        mv \${FASTQ_BASENAME}.fastq.stats
    
        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            fastx_toolkit: \$(fastx_quality_stats -h | grep FASTX | awk '{print \$5}')
        END_VERSIONS
        """
}