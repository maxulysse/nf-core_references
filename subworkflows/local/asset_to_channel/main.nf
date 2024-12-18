workflow ASSET_TO_CHANNEL {
    take:
    asset // channel: [meta, fasta]

    main:

    // All the files and meta data are contained in the meta map (except for fasta)
    // They are extracted out of the meta map in their own channel in this subworkflow
    // When adding a new field in the assets/schema_input.json, also add it in the meta map
    // And in this scrip, add a new map operation and a new output corresponding to this input

    // If any of the asset does not exist, then we return null
    // That way, the channel will be empty and does not trigger anything

    def reduce = { meta -> meta.subMap(['genome', 'id', 'source', 'source_vcf', 'source_version', 'species']) }

    intervals_bed = asset.map { meta, _fasta -> meta.intervals_bed ? [reduce(meta), file(meta.intervals_bed)] : null }

    // If ends with .gz, decompress it
    // If any of the asset exists, then adding run_tools to false and skip the asset creation from the fasta file
    fasta = asset.map { meta, fasta_ -> fasta_ ? [reduce(meta) + [decompress_fasta: fasta_.endsWith('.gz') ?: false] + [run_bowtie1: meta.bowtie1_index ? false : true] + [run_bowtie2: meta.bowtie2_index ? false : true] + [run_bwamem1: meta.bwamem1_index ? false : true] + [run_bwamem2: meta.bwamem2_index ? false : true] + [run_dragmap: meta.dragmap_hashtable ? false : true] + [run_faidx: meta.fasta_fai && meta.fasta_sizes ? false : true] + [run_gatkdict: meta.fasta_dict ? false : true] + [run_hisat2: meta.hisat2_index ? false : true] + [run_intervals: meta.intervals_bed ? false : true] + [run_kallisto: meta.kallisto_index ? false : true] + [run_msisenpro: meta.msisensorpro_list ? false : true] + [run_rsem: meta.rsem_index ? false : true] + [run_rsem_make_transcript_fasta: meta.transcript_fasta ? false : true] + [run_salmon: meta.salmon_index ? false : true] + [run_star: meta.star_index ? false : true], file(fasta_)] : null }

    fasta_dict = asset.map { meta, _fasta -> meta.fasta_dict ? [reduce(meta), file(meta.fasta_dict)] : null }

    // If we have intervals_bed, then we don't need to run faidx
    fasta_fai = asset.map { meta, _fasta -> meta.fasta_fai ? [reduce(meta) + [run_intervals: meta.intervals_bed ? false : true], file(meta.fasta_fai)] : null }

    fasta_sizes = asset.map { meta, _fasta -> meta.fasta_sizes ? [reduce(meta), file(meta.fasta_sizes)] : null }

    // If ends with .gz, decompress it
    // If any of the asset exists, then adding run_tools to false and skip the asset creation from the annotation derived file (gff, gtf or transcript_fasta)
    gff = asset.map { meta, fasta_ -> meta.gff ? [reduce(meta) + [decompress_gff: meta.gff.endsWith('.gz') ?: false] + [run_gffread: fasta_ && !meta.gtf ?: false] + [run_hisat2: meta.splice_sites ? false : true], file(meta.gff)] : null }

    // If ends with .gz, decompress it
    // If any of the asset exists, then adding run_tools to false and skip the asset creation from the annotation derived file (gff, gtf or transcript_fasta)
    gtf = asset.map { meta, _fasta -> meta.gtf ? [reduce(meta) + [decompress_gtf: meta.gtf.endsWith('.gz') ?: false] + [run_hisat2: meta.splice_sites ? false : true], file(meta.gtf)] : null }

    splice_sites = asset.map { meta, _fasta -> meta.splice_sites ? [reduce(meta), file(meta.splice_sites)] : null }

    // If any of the asset exists, then adding run_tools to false and skip the asset creation from the annotation derived file (gff, gtf or transcript_fasta)
    transcript_fasta = asset.map { meta, _fasta -> meta.transcript_fasta ? [reduce(meta) + [run_hisat2: meta.hisat2_index ? false : true] + [run_kallisto: meta.kallisto_index ? false : true] + [run_rsem: meta.rsem_index ? false : true] + [run_salmon: meta.salmon_index ? false : true] + [run_star: meta.star_index ? false : true], file(meta.transcript_fasta)] : null }

    // Using transpose here because we want to catch vcf with globs in the path because of nf-core/Sarek
    // If we already have the vcf_tbi, then we don't need to index the vcf
    vcf = asset.map { meta, _fasta -> meta.vcf ? [reduce(meta) + [run_tabix: meta.vcf_tbi ? false : true], file(meta.vcf)] : null }.transpose()

    intervals_bed.view { "intervals_bed: " + it }
    fasta.view { "fasta: " + it }
    fasta_dict.view { "fasta_dict: " + it }
    fasta_fai.view { "fasta_fai: " + it }
    fasta_sizes.view { "fasta_sizes: " + it }
    gff.view { "gff: " + it }
    gtf.view { "gtf: " + it }
    splice_sites.view { "splice_sites: " + it }
    transcript_fasta.view { "transcript_fasta: " + it }
    vcf.view { "vcf: " + it }

    emit:
    intervals_bed    // channel: [meta, *.bed]
    fasta            // channel: [meta, *.f(ast|n)?a]
    fasta_dict       // channel: [meta, *.f(ast|n)?a.dict]
    fasta_fai        // channel: [meta, *.f(ast|n)?a.fai]
    fasta_sizes      // channel: [meta, *.f(ast|n)?a.sizes]
    gff              // channel: [meta, gff]
    gtf              // channel: [meta, gtf]
    splice_sites     // channel: [meta, *.splice_sites.txt]
    transcript_fasta // channel: [meta, *.transcripts.fasta]
    vcf              // channel: [meta, *.vcf.gz]
}