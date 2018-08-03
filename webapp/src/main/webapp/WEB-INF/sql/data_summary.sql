WITH datacategory as (

SELECT
	dt.id dataset_id,
	ds.id datasource_id,
	dt.name dataset_name,
	ds.name datasource_name,
	case
		when (ds.name = 'GO')
			then true
		else
			false
	end as hide_empty_rows,
	case
		when (dt.name = 'Genome Assembly')
		then 'Genome Assembly'
		when (dt.name = 'Genome Annotation' or dt.name = 'Coding Sequence FASTA')
		then 'Genes'
	   when (
			dt.name = 'Swiss-Prot data set' OR
			dt.name = 'TrEMBL data set' OR
			dt.name = 'UniProt FASTA dataset' OR
			dt.name = 'UniProt keywords data set' OR
			dt.name = 'Protein Sequence FASTA' or
			dt.name = 'InterPro data set'
			)
		then 'Proteins'
		when (dt.name = 'Panther data set')
	   	then 'Homology'
	   	when (ds.name = 'GO' or dt.name = 'InterPro GO Annotation data set')
		then 'Gene Ontology'
		when (dt.name = 'IntAct interactions data set' or dt.name = 'BioGRID interaction data set')
			then 'Interactions'
		when (dt.name = 'atgenexp_hormone' or
			dt.name = 'atgenexp' or
			dt.name = 'atgenexp_pathogen' or
			dt.name = 'atgenexp_plus' or
			dt.name = 'light_series' or
			dt.name = 'atgenexp_stress' or
			dt.name = 'root' or
	   		dt.name = 'seed_db' or
			dt.name = 'affydb' or
			dt.name = 'arabidopsis_ecotypes'
			)
		then 'Expression'
		when (dt.name = 'PubMed to gene mapping')
		then 'Publications'
		when (dt.name = 'GeneRIF')
		then 'GeneRIF'
		when (dt.name = 'KEGG pathways data set')
		then 'Pathways'
		when (dt.name = 'PO Annotation from TAIR')
		then 'Plant Ontology'
		when (dt.name = 'TAIR Germplasm')
		then 'Germplasm/Seed Stock'
		when (dt.name = 'TAIR Polymorphism')
		then 'Mutant Alleles'
		when (dt.name = 'TAIR Phenotypes')
		then 'Phenotypes'
		when (dt.name = 'RNA-seq expression')
		then 'Expression'
        when (ds.name = 'SIGnAL')
        then 'TDNA-seq'
		else ds.name

	 end as category_name
FROM
	datasource ds JOIN dataset dt
		ON
		ds.id = dt.datasourceid
)

,
sort as (

select
	dataset_id,
	datasource_id,
	dataset_name,
	category_name,
	hide_empty_rows,
	case
		when (category_name = 'Genome Assembly')
			then -2
		when (category_name = 'Genes')
			then -1
		when (category_name = 'Proteins')
			then 2
		when (category_name = 'Proteins Domains')
			then 3
		when (category_name = 'Homology')
			then 4
		when (category_name = 'Gene Ontology')
			then 5
		when (category_name = 'Plant Ontology')
			then 6
		when (category_name = 'Interactions')
			then 7
		when (category_name = 'Expression')
			then 8
		when (category_name = 'Publications')
			then 9
		when (category_name = 'GeneRIF')
			then 10
		when (category_name = 'Pathways')
			then 11
		when (category_name = 'Germplasm/Seed Stock')
			then 12
		when (category_name = 'Phenotypes')
			then 14
		when (category_name = 'Mutant Alleles')
			then 15
        when (category_name = 'TDNA-Seq')
            then 16
		else
			999
	end as sort_order
from
datacategory dc
where dataset_name not in  ('RNA-seq expression', 'SRA', 'TAIR Polymorphism', 'TAIR Phenotypes', 'TAIR Germplasm', 'TAIR Ecotypes', 'Genome Annotation', 'ATTED-II Co-expression', 'Phytozome Orthologs', 'Gene Summary', 'IntAct', 'BioGRID', 'PO Annotation from TAIR','Panther data set', 'BAR Annotations Lookup', 'Coding Sequence FASTA', 'Protein Sequence FASTA', 'UniProt FASTA dataset', 'UniProt keywords data set')
and dc.datasource_name not in ('BAR', 'InterPro', 'GO', 'IntAct', 'BioGRID', 'SIGnAL')
)
,
publication_source as (
SELECT
	p.id,
	p.pubmedid pubmed_id,
	p.title,
	p.intermine_year as year,
	p.firstauthor  as author_list
FROM
	publication p
),

gene_pub_source as (
SELECT
	distinct
	count(distinct p.pubmedid) feature_count,
	(select d.id from dataset d where d.name = 'PubMed to gene mapping' limit 1) dataset_id
FROM
	gene g JOIN bioEntitiespublications bp
		ON
		bp.bioentities = g.id JOIN publication p
		ON
		p.id = bp.publications
		join organism o on
		g.organismid = o.id and o.taxonid = 3702
		)
,
gene_rif_pub_agg_source as (
select
count(*) as feature_count,
(select d.id from dataset d where d.name = 'GeneRIF' limit 1) dataset_id
from generif gr
join
gene g
on g.id = gr.geneid
join
publication p
on gr.publicationid = p.id
join organism o on
g.organismid = o.id and o.taxonid = 3702
)
,

ncbi_pub_agg_source as (
select
feature_count,
dataset_id
from
gene_pub_source gs
)
,
gene_agg_source as (
select
count(*) as gene_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
organism o
on
o.id = g.organismid
where o.taxonid = 3702 and g.isobsolete = false and d.name not in  ('IntAct', 'BioGRID', 'Panther data set', 'BAR Annotations Lookup', 'Coding Sequence FASTA', 'Protein Sequence FASTA', 'UniProt FASTA dataset', 'UniProt keywords data set')
group by d.id
)
,
gene_summary_helper as (
select
d.id as dataset_id,
cast(count(distinct g.primaryidentifier) as text) as gene_count,
cast(NULL as text ) as feature_count
from gene g
join
organism o
on o.id = g.organismid
join
cds c
on
c.geneid = g.id
join
bioentitiesdatasets bds
on g.id = bds.bioentities
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702
and g.isobsolete = false
and d.name = 'Genome Annotation'
group by d.id
),

transposable_element_gene_helper as (

select
d.id as dataset_id,
cast(count(distinct g.primaryidentifier) as text) as gene_count,
cast(NULL as text ) as feature_count
from gene g
join
organism o
on o.id = g.organismid
join
ontologyterm sg
on sg.id = g.sequenceontologytermid
join
bioentitiesdatasets bds
on g.id = bds.bioentities
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702
and sg.name = 'transposable_element_gene' and d.name = 'Genome Annotation'
group by d.id

)
,

pseudogene_helper as (
select
d.id as dataset_id,
cast(count(distinct g.primaryidentifier) as text) as gene_count,
cast(NULL as text ) as feature_count
from gene g
join
organism o
on o.id = g.organismid
join
ontologyterm sg
on sg.id = g.sequenceontologytermid
join
bioentitiesdatasets bds
on g.id = bds.bioentities
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702
and sg.name = 'pseudogene' and d.name = 'Genome Annotation'
group by d.id
)

,

non_coding_genes_helper as (
select
d.id as dataset_id,
cast(count(distinct nc.geneid) as text) as gene_count,
cast(count(distinct nc.primaryidentifier) as text) as feature_count
from transcript nc
join
organism o
on o.id = nc.organismid
join
ontologyterm sn
on sn.id = nc.sequenceontologytermid
join
bioentitiesdatasets bds
on nc.id = bds.bioentities
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702
and sn.name in ('tRNA', 'pseudogenic_tRNA', 'miRNA_primary_transcript', 'snRNA', 'snoRNA', 'rRNA', 'lnc_RNA', 'antisense_lncRNA', 'antisense_RNA', 'ncRNA')
and
d.name = 'Genome Annotation'
group by d.id

)
,

ntr_genes_helper as (
select
d.id as dataset_id,
cast(count(distinct ntr.geneid) as text) as gene_count,
cast(count(distinct ntr.primaryidentifier) as text) as feature_count
from transcript ntr
join
organism o
on o.id = ntr.organismid
join
ontologyterm sn
on sn.id = ntr.sequenceontologytermid
join
bioentitiesdatasets bds
on ntr.id = bds.bioentities
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702
and sn.name = 'transcript_region' and d.name = 'Genome Annotation'
group by d.id

)
,

transposable_element_helper as
(
select
cast(count(distinct tf.transposableelementid) as text) as gene_count,
cast(count(distinct tf.primaryidentifier) as text) as feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join transposonfragment tf
on tf.id = bds.bioentities
join
transposableelement te
on te.id = tf.transposableelementid
group by d.id
),

uorf_helper as
(
select
cast(count(*) as text) as gene_count,
cast(count(*) as text) as feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join uorf u
on u.id = bds.bioentities
join
gene g
on g.id = u.geneid
group by d.id),

gene_summary_source as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genes' as text) as category_name,
-1 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
cast('Protein-coding genes' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - Araport11 (06/2016)' as text) as dataset_name,
d.url dataset_url,
p.pubmed_id,
cast('Cheng and Krishnakumar et al.' as text) as authors,
2016 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
gene_summary_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genes' as text) as category_name,
1 as sort_order,
(select ds.id from datasource ds where ds.name = 'TAIR' limit 1) as datasource_id,
(select ds.name from datasource ds where ds.name = 'TAIR' limit 1)  as datasource_name,
(select ds.url from datasource ds where ds.name = 'TAIR' limit 1) as  datasource_url,
(select ds.description from datasource ds where ds.name = 'TAIR' limit 1)  as datasource_description,
cast('Transposable Element genes' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - TAIR10' as text) as dataset_name,
cast ('http://arabidopsis.org/portals/genAnnotation/gene_structural_annotation/agicomplete.jsp' as text) as dataset_url,
p.pubmed_id,
cast('Lamesch et al.,' as text) as authors,
2012 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
transposable_element_gene_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genes' as text) as category_name,
-1 as sort_order,
(select ds.id from datasource ds where ds.name = 'Araport' limit 1) as datasource_id,
(select ds.name from datasource ds where ds.name = 'Araport' limit 1)  as datasource_name,
(select ds.url from datasource ds where ds.name = 'Araport' limit 1) as  datasource_url,
(select ds.description from datasource ds where ds.name = 'Araport' limit 1)  as datasource_description,
cast('Pseudogenes' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - Araport11 (06/2016)' as text) as dataset_name,
cast ('http://www.araport.org/data/araport11' as text) as dataset_url,
p.pubmed_id,
cast('Cheng and Krishnakumar et al.' as text) as authors,
2016 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
pseudogene_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genes' as text) as category_name,
0 as sort_order,
(select ds.id from datasource ds where ds.name = 'Araport' limit 1) as datasource_id,
(select ds.name from datasource ds where ds.name = 'Araport' limit 1)  as datasource_name,
(select ds.url from datasource ds where ds.name = 'Araport' limit 1) as  datasource_url,
(select ds.description from datasource ds where ds.name = 'Araport' limit 1)  as datasource_description,
cast('Non-coding genes' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - Araport11 (06/2016)' as text) as dataset_name,
cast ('http://www.araport.org/data/araport11' as text) as dataset_url,
p.pubmed_id,
cast('Cheng and Krishnakumar et al.' as text) as authors,
2016 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
non_coding_genes_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genes' as text) as category_name,
0 as sort_order,
(select ds.id from datasource ds where ds.name = 'Araport' limit 1) as datasource_id,
(select ds.name from datasource ds where ds.name = 'Araport' limit 1)  as datasource_name,
(select ds.url from datasource ds where ds.name = 'Araport' limit 1) as  datasource_url,
(select ds.description from datasource ds where ds.name = 'Araport' limit 1)  as datasource_description,
cast('Novel Transcribed Regions' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - Araport11 (06/2016)' as text) as dataset_name,
cast ('http://www.araport.org/data/araport11' as text) as dataset_url,
p.pubmed_id,
cast('Cheng and Krishnakumar et al.' as text) as authors,
2016 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
ntr_genes_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genomic Features' as text) as category_name,
2 as sort_order,
(select ds.id from datasource ds where ds.name = 'TAIR' limit 1) as datasource_id,
(select ds.name from datasource ds where ds.name = 'TAIR' limit 1)  as datasource_name,
(select ds.url from datasource ds where ds.name = 'TAIR' limit 1) as  datasource_url,
(select ds.description from datasource ds where ds.name = 'TAIR' limit 1)  as datasource_description,
cast('Transposable Elements' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - TAIR10' as text) as dataset_name,
cast ('http://arabidopsis.org/portals/genAnnotation/gene_structural_annotation/agicomplete.jsp' as text) as dataset_url,
p.pubmed_id,
cast('Lamesch et al.,' as text) as authors,
2012 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
transposable_element_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
UNION
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Genomic Features' as text) as category_name,
2 as sort_order,
ds.id as datasource_id,
ds.name as datasource_name,
ds.url as datasource_url,
cast('Genome Annotation - Araport11 (06/2016)' as text) as datasource_description,
cast('Upstream Open Reading Frames' as text) as dataset_description,
gh.dataset_id,
cast('Genome Annotation - Araport11 (06/2016)' as text) as dataset_name,
cast ('http://www.araport.org/data/araport11' as text) as dataset_url,
p.pubmed_id,
cast('Cheng and Krishnakumar et al.,' as text) as authors,
2016 as year,
cast ('' as text) as dataset_version,
gh.gene_count,
gh.feature_count
from
uorf_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
)
,
pub_agg_feature_source as (
select
feature_count,
dataset_id
from
gene_rif_pub_agg_source
UNION
select
feature_count,
dataset_id
from
ncbi_pub_agg_source
 )
,

protein_agg_source as (

select
count(distinct(proteins)) feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
genesproteins gp
on gp.genes = g.id
join protein p
on p.id = gp.proteins
join organism o
on o.id = g.organismid
where o.taxonid = 3702 and ds.name = 'UniProt'
and p.uniprotname IS NOT NULL
group by d.id
)
,

po_summary_helper as(
SELECT
	cast(count(distinct g.primaryidentifier) as text) as gene_count,
	cast(count(*) as text) feature_count,
	d.id dataset_id
	from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
genepoannotation go
on go.gene = g.id
join organism o
on o.id = g.organismid
where o.taxonid = 3702 and d.name = 'PO Annotation from TAIR'
group by d.id

),

po_summary_source as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Plant Ontology' as text) as category_name,
6 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
d.name dataset_description,
gh.dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
gh.gene_count,
gh.feature_count
from
po_summary_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
)
,
generif_agg_source as (
SELECT
	count(distinct(annotation)) feature_count,
	d.id dataset_id
	from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
generif gr
on g.id = gr.geneid
join organism o
on o.id = g.organismid
where o.taxonid = 3702 and d.name = 'GeneRIF'
group by d.id

)
,
agg_pathways_source as (

select
count(distinct(pathways)) feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
genespathways gp
on g.id = gp.genes
join organism o
on o.id = g.organismid
where o.taxonid = 3702 and d.name = 'KEGG pathways data set'
group by
d.id

),

genome_assembly_agg_source as (
select count(*) feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets ds
on
d."id" = ds.datasets
join sequencefeature g
on g."id" = ds.bioentities
where d.name = 'Genome Assembly'
group by d.id
),

cds_agg_source as (
select count(*) feature_count,
d.id dataset_id
from dataset d
join
bioentitiesdatasets ds
on
d."id" = ds.datasets
join cds c
on c.id = ds.bioentities
join
gene g
on g.id = c.geneid
group by d.id)

,
agg_feature_count_helper as
(
select
feature_count,
dataset_id
from
cds_agg_source
UNION
select
feature_count,
dataset_id
from
genome_assembly_agg_source
UNION
select
feature_count,
dataset_id
from
pub_agg_feature_source
UNION
select
feature_count,
dataset_id
from
protein_agg_source
UNION
select
feature_count,
dataset_id
from
agg_pathways_source
)
,

agg_feature_count as (
select
feature_count,
dataset_id,
ds.id datasource_id
from
agg_feature_count_helper
join
dataset dt
on dataset_id = dt.id
join
datasource ds
on ds.id = dt.datasourceid
)
,
feature_data_source_agg as
(
select
sum(feature_count) feature_count,
datasource_id
from
agg_feature_count
group by
datasource_id
)
,
gene_data_source_agg as (
select
count(*) as gene_count,
ds.id datasource_id
from dataset d
join
bioentitiesdatasets bds
on
d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join gene g
on g.id = bds.bioentities
join
organism o
on
o.id = g.organismid
where o.taxonid = 3702 and d.name not in ('IntAct', 'BioGRID', 'Panther data set') and ds.name not in ('IntAct', 'BioGRID')
group by ds.id )
,
data_summary_source as(
SELECT
	distinct
	cast('summary' as text) as row_type,
	0 as parent_dataset_id,
	st.category_name,
	st.sort_order,
	st.hide_empty_rows,
	ds.name datasource_name,
	ds.id datasource_id,
	ds.url datasource_url,
	ds.description datasource_description,
	case
		when (ds.name = 'GO' or ds.name = 'BAR')
			then
				ds.description
		when (dt.name = 'PubMed to gene mapping')
			then
				'Curated associations between publications and genes'
		 else dt.description
	end as dataset_description,
	case
		when (ds.name = 'GO' or ds.name = 'BAR')
			then
				ds.id
		 else dt.id
	end as dataset_id,
	case
		when (ds.name = 'GO' or ds.name = 'BAR')
			then
				ds.name
		 else dt.name
	end as dataset_name,
	dt.version dataset_version,
	case
		when (ds.name = 'GO' or ds.name = 'BAR')
			then
				ds.url
		 else dt.url
	end as dataset_url,
	p.pubmed_id,
	p.author_list as authors,
	p.year,
	case
		when (ds.name = 'GO')
			then
				gds.gene_count
		 else gs.gene_count
	end as gene_count,
	gds.gene_count data_source_gene_count,
	case
		when (ds.name = 'GO')
			then
				agg_f_ds.feature_count
		 else aggf.feature_count
	end as feature_count,
	agg_f_ds.feature_count data_source_feature_count
	FROM
	datasource ds JOIN dataset dt
		ON
		ds.id = dt.datasourceid
		join
		sort st
		on st.dataset_id = dt.id and st.datasource_id = ds.id
		left join
	publication_source p
	on p.id = dt.publicationid
	left join
	gene_agg_source gs
	on gs.dataset_id = dt.id
	left join
	agg_feature_count aggf
	on aggf.dataset_id = dt.id
	left join
	gene_data_source_agg gds
	on gds.datasource_id = ds.id
	left join
	feature_data_source_agg agg_f_ds
	on agg_f_ds.datasource_id = ds.id
	where dt.name <> 'BAR Annotations Lookup'
	order by st.sort_order )

,

stock_agg_source as (
select
count(distinct ge.primaryidentifier) as gene_count,
count(distinct s.id) feature_count,
cast('TAIR Germplasm' as text) as dataset_name
from stock s
left
join
genotypesstocks gs
on gs.stocks = s.id
left
join
genotype g
on g.id = gs.genotypes
left
join
allelesgenotypes als
on als.genotypes = g.id
left
join
allele a
on a.id = als.alleles
left
join
affectedallelesaffectedgenes afg
on afg.affectedalleles = a.id
left
join
gene ge
on ge.id = afg.affectedgenes
),

stock_summary as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Germplasms/Seed Stocks' as text) as category_name,
12 as sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
d.description as dataset_description,
d.id as dataset_id,
cast('Germplasm/Seed Stock' as text) as dataset_name,
d.url as dataset_url,
cast('' as text ) as pubmed_id,
cast('' as text) as authors,
0 as year,
cast('10/2013' as text ) as dataset_version,
cast(st.gene_count as text) as gene_count,
cast(st.feature_count as text) as feature_count
FROM
	datasource ds JOIN dataset d
		ON
		ds.id = d.datasourceid
join
stock_agg_source st
on st.dataset_name = d.name
		where d.name = 'TAIR Germplasm'
		)
		,
phenotype_agg_source as (

select
count(ge.primaryidentifier) as gene_count,
count(distinct s.id) feature_count,
cast('TAIR Phenotypes' as text) as dataset_name
from phenotype s
left
join
observedinphenotypesobserved gs
on gs.phenotypesobserved = s.id
left
join
genotype g
on g.id = gs.observedin
left
join
allelesgenotypes als
on als.genotypes = g.id
left
join
allele a
on a.id = als.alleles
left
join
affectedallelesaffectedgenes afg
on afg.affectedalleles = a.id
left
join
gene ge
on ge.id = afg.affectedgenes

)
,
phenotype_summary as (

select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Phenotypes' as text) as category_name,
14 as sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
cast('Germplasm/Stock Phenotypes' as text) as dataset_description,
d.id as dataset_id,
cast('Germplasm/Stock Phenotypes' as text) as dataset_name,
d.url as dataset_url,
cast('' as text ) as pubmed_id,
cast('' as text) as authors,
0 as year,
cast('10/2013' as text ) as dataset_version,
cast(st.gene_count as text) as gene_count,
cast(st.feature_count as text) as feature_count
FROM
	datasource ds JOIN dataset d
		ON
		ds.id = d.datasourceid
join
phenotype_agg_source st
on st.dataset_name = d.name
		where d.name = 'TAIR Phenotypes'

)
,
expression_datasource as
(
select
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
ds.description dataset_description,
d.id dataset_id,
ds.description dataset_name,
ds.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version
from dataset d
join
datasource ds
on d.datasourceid = ds.id
left join
publication_source p
on p.id = d.publicationid
where ds.name = 'BAR'
)
,

efp_summary as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Expression' as text) category_name,
8 sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url as datasource_url,
ds.description as datasource_description,
d.description dataset_description,
d.id dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
cast('real-time' as text) as gene_count,
cast('real-time' as text) as feature_count
from dataset d
join
datasource ds
on ds.id = d.datasourceid
left join
publication_source p
on p.id = d.publicationid
where d.name = 'Arabidopsis eFP')
,
expression_summary_helper as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast ('Expression' as text) category_name,
8 sort_order,
eds.datasource_id,
eds.datasource_name,
eds.datasource_url,
eds.datasource_description,
eds.dataset_description,
eds.dataset_id,
eds.dataset_name,
eds.dataset_url,
eds.dataset_version,
eds.pubmed_id,
eds.authors,
eds.year,
24005 as gene_count,
123 as feature_count
from
expression_datasource eds
limit 1
)
,
expression_summary as (
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
NULL as dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
expression_summary_helper
UNION
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
efp_summary
)

,
phytozome_summary as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Homology' as text) as category_name,
4 sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url as datasource_url,
ds.description as datasource_description,
d.description dataset_description,
d.id dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
0 as gene_count,
0 as feature_count
from dataset d
join
datasource ds
on ds.id = d.datasourceid
left join
publication_source p
on p.id = d.publicationid
where d.name = 'Phytozome Orthologs'
)
,

atgen_express_summary as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Co-Expression' as text) category_name,
8 sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url as datasource_url,
ds.description as datasource_description,
d.description dataset_description,
d.id dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
0 as gene_count,
0 as feature_count
from dataset d
join
datasource ds
on ds.id = d.datasourceid
left join
publication_source p
on p.id = d.publicationid
where d.name = 'ATTED-II Co-expression'

)
,

homologs_summary_source as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Homology' as text) as category_name,
4 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
case
	when (d.url is not null)
		then replace(ds.url, 'https', 'http')
	else
		ds.url
end as datasource_url,
ds.description as datasource_description,
d.description dataset_description,
d.id dataset_id,
d.name dataset_name,
case
	when (d.url is not null)
		then replace(d.url, 'https', 'http')
	else
		d.url
end as dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
cast(count(distinct abg.primaryidentifier) as text) as gene_count,
cast(count(distinct be.primaryidentifier) as text) as feature_count
from
gene g
join
bioentitiesdatasets bds
on bds.bioentities = g.id
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join homologue h
on g.id = h.geneid
join bioentity be
on be.id = h.homologueid
join
gene abg
on
g.id = abg.id
join
bioentitiesdatasets bdsa
on bdsa.bioentities = abg.id
join dataset abda
on abda.id = bdsa.datasets
left join
	publication_source p
	on p.id = d.publicationid
where d.name = 'Panther data set' and abda.name = 'Genome Annotation'
group by d.id, ds.id, ds.name, d.name, d.description, ds.description, d.version, ds.url, d.url, p.pubmed_id, p.author_list, p.year )
,

rnaseq_summary_helper as(
select count(*) as gene_count,
cast(count(distinct r.expressionofid) as text) as feature_count,
dt.id dataset_id
from rnaseqexpression r
join
rnaseqexperiment rn
on r.experimentid = rn.id
join dataset dt
on dt.id = r.datasetid
where r.type = 'gene'
and
rn.sraaccession = 'ERR274309'
group by dt.id)
,

rnaseq_summary_source as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Expression' as text) as category_name,
8 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
cast('RNA-seq based gene expression levels (Transcripts per Million, TPM) quantified by Salmon' as text) dataset_description,
gh.dataset_id,
d.name dataset_name,
d.url dataset_url,
cast('http://biorxiv.org/content/early/2016/04/05/047308' as text ) as pubmed_id,
cast('Cheng and Krishnakumar et al.' as text) as authors,
2016 as year,
d.version as dataset_version,
cast(gh.gene_count as text) as gene_count,
cast('113 datasets from 11 tissues' as text) as feature_count
from
rnaseq_summary_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
)
,

interactions_summary_helper as (
select
cast(count(distinct g.primaryidentifier) as text) as gene_count,
cast(count(*) as text) feature_count,
d.id dataset_id
from dataset d
join
datasetsinteractiondetail dl
on d.id = dl.datasets
join
interactiondetail ind on
ind.id = dl.interactiondetail
join
interaction i
on i.id = ind.interactionid
join
gene g
on g.id = i.participant1id
group by d.id
)
,

interactions_summary_source as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Interactions' as text) as category_name,
7 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
d.description dataset_description,
gh.dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
gh.gene_count,
gh.feature_count
from
interactions_summary_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
       publication_source p
       on p.id = d.publicationid

)
,

protein_domain_summary_helper as (
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Protein Domains' as text) as category_name,
3 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
d.description dataset_description,
d.id dataset_id,
d.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
count(distinct g.primaryidentifier)  gene_count,
count (distinct pd.id) as feature_count
from
genesproteins gp
join
gene g
on g.id = gp.genes
join
protein pt
on pt.id = gp.proteins
join
proteindomainregion ptd
on ptd.proteinid = pt.id
join
proteindomain pd
on pd.id = ptd.proteindomainid
join
bioentitiesdatasets bds
on bds.bioentities = pt.id
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
join
organism o
on
o.id = g.organismid
left join
       publication_source p
       on p.id = d.publicationid
where o.taxonid = 3702 and pt.uniprotname IS NOT NULL and ds.name = 'InterPro'
group by d.id, ds.id, ds.name, d.name, d.description, ds.description, d.version, ds.url, d.url, p.pubmed_id, p.author_list, p.year

),

gene_ontology_summary_helper as (
SELECT
(select d.id from dataset d join datasource ds on ds.id = d.datasourceid where ds.name = 'GO' limit 1)  as dataset_id,
cast(count(distinct g.primaryidentifier) as text) as gene_count,
cast(count(*) as text) feature_count
from
genegoannotation go
join gene g
on g.id = go.gene
join organism o
on o.id = g.organismid
join
goannotation goa
on go.goannotation = goa.id
join
ontologyterm ot
on ot.id = goa.ontologytermid
join
bioentitiesdatasets bds
on bds.bioentities = g.id
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702 and ds.name = 'GO'

),

salk_tdnaseq_summary_helper as (
SELECT
(select d.id from dataset d join datasource ds on ds.id = d.datasourceid where ds.name = 'SIGnAL' limit 1)  as dataset_id,
cast('38772' as text) as gene_count,
cast(count(*) as text) feature_count
from
transposableelementinsertionsite tdnaseq
join organism o
on o.id = tdnaseq.organismid
join
bioentitiesdatasets bds
on bds.bioentities = tdnaseq.id
join
dataset d
on d.id = bds.datasets
join
datasource ds
ON
ds.id = d.datasourceid
where o.taxonid = 3702 and ds.name = 'SIGnAL'

),

allele_agg_source as (
select
count(distinct ge.primaryidentifier) as gene_count,
count(distinct s.id) feature_count,
cast('TAIR Polymorphism' as text) as dataset_name
from allele s
left
join
affectedallelesaffectedgenes afg
on afg.affectedalleles = s.id
left
join
gene ge
on ge.id = afg.affectedgenes
),

allele_summary as(
select
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Mutant Alleles' as text) as category_name,
15 as sort_order,
ds.id datasource_id,
ds.name as datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
cast('Alleles/Polymorphisms' as text) as dataset_description,
d.id as dataset_id,
cast('Alleles/Polymorphisms' as text) as dataset_name,
d.url as dataset_url,
cast('' as text ) as pubmed_id,
cast('' as text) as authors,
0 as year,
cast('10/2013' as text ) as dataset_version,
cast(st.gene_count as text) as gene_count,
cast(st.feature_count as text) as feature_count
FROM
	datasource ds JOIN dataset d
		ON
		ds.id = d.datasourceid
join
allele_agg_source st
on st.dataset_name = d.name
		where d.name = 'TAIR Polymorphism'
)

,
gene_ontology_summary as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('Gene Ontology' as text) as category_name,
5 as sort_order,
ds.id datasource_id,
ds.name datasource_name,
ds.url datasource_url,
ds.description as datasource_description,
ds.description dataset_description,
(select d.id from dataset d join datasource ds on ds.id = d.datasourceid where ds.name = 'GO' limit 1)  as dataset_id,
ds.name dataset_name,
d.url dataset_url,
p.pubmed_id,
p.author_list as authors,
p.year,
d.version dataset_version,
gh.gene_count,
gh.feature_count
from
gene_ontology_summary_helper gh
join dataset d
on d.id = gh.dataset_id
join
datasource ds
on ds.id = d.datasourceid
left join
	publication_source p
	on p.id = d.publicationid
)
,
salk_tdnaseq_summary as (
SELECT
distinct
cast('summary' as text) as row_type,
0 as parent_dataset_id,
cast('TDNA-Seq' as text) as category_name,
16 as sort_order,
ds.id datasource_id,
  ds.name datasource_name,
  ds.url datasource_url,
  ds.description as datasource_description,
  d.description dataset_description,
  (select d.id from dataset d join datasource ds on ds.id = d.datasourceid where ds.name = 'SIGnAL' limit 1)  as dataset_id,
  d.name dataset_name,
  d.url dataset_url,
  p.pubmed_id,
  p.author_list as authors,
  p.year,
  d.version dataset_version,
  th.gene_count,
  th.feature_count
  from
  salk_tdnaseq_summary_helper th
  join dataset d
  on d.id = th.dataset_id
  join datasource ds
  on ds.id = d.datasourceid
  join datasourcepublications dp
  on dp.datasource = ds.id
  left join publication_source p
  on p.id = dp.publications
)
,
data_summary_source_units as (
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
data_summary_source
UNION
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
expression_summary
UNION
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
interactions_summary_source
UNION
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast(gene_count as text) as gene_count,
cast(feature_count as text) as feature_count
from
protein_domain_summary_helper
UNION
select
distinct
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast('real-time' as text) as gene_count,
cast('real-time' as text) as feature_count
from
phytozome_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
cast('real-time' as text) as gene_count,
cast('real-time' as text) as feature_count
from
atgen_express_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
homologs_summary_source
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
gene_ontology_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
po_summary_source
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
gene_summary_source
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
stock_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
phenotype_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
allele_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from
salk_tdnaseq_summary
UNION
select
row_type,
parent_dataset_id,
category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
datasource_description,
dataset_description,
dataset_id,
dataset_name,
dataset_url,
dataset_version,
pubmed_id,
authors,
year,
gene_count,
feature_count
from rnaseq_summary_source
)

select
row_type,
parent_dataset_id,
case
	when(category_name = 'Genome Assembly')
		then 'Chromosomes'
	else
		category_name
end as category_name,
sort_order,
datasource_id,
datasource_name,
datasource_url,
case when (category_name = 'Genome Assembly' or category_name = 'Genes' )
		then cast (NULL as text)
	else datasource_description
end as datasource_description,
dataset_description,
dataset_id,
case
	 when (dataset_name = 'PubMed to gene mapping')
	 	then 'Gene to PubMed'
	 	else
	 	dataset_name
end dataset_name,
dataset_url,
dataset_version,
case
	when (dataset_description = 'Upstream Open Reading Frames' or dataset_description = 'Non-coding genes'
	or dataset_description = 'Pseudogenes' or dataset_description = 'Protein-coding genes'
    or dataset_description = 'Novel Transcribed Regions')
	then 'http://dx.doi.org/10.1101/047308'
	when (dataset_description = 'Transposable Element genes'
    or dataset_description = 'Transposable Elements')
	then cast(22140109 as text)
	else
	pubmed_id
end pubmed_id,
case
	 when (datasource_name = 'Araport' and dataset_name = 'RNA-seq expression')
	 	then 'Manuscript in preparation'
	 	else
	 	NULL
end pub_title,
authors,
case when(year = 0)
	then null
	else
		year
end as year,
gene_count,
feature_count,
case
	when (category_name = 'Proteins')
		then 'proteins'
	when (category_name = 'Protein Domains')
		then 'protein domains'
	when (category_name = 'Homology' and dataset_version <> 'real-time')
		then 'homologs'
	when (category_name = 'Gene Ontology')
		then 'GO annotations'
	when (category_name = 'Plant Ontology')
		then 'PO annotations'
	when (category_name = 'Interactions')
		then 'interactions'
	when (category_name = 'Expression' and dataset_description = 'The Bio-Analaytic Resource for Plant Biology')
		then 'experiments'
	when (category_name = 'Publications')
		then 'publications'
	when (category_name = 'GeneRIF')
		then 'GeneRIF Annotations'
	when (category_name = 'Pathways')
		then 'pathways'
    when (category_name = 'Germplasms/Seed Stocks')
		then 'stocks'
	when (category_name = 'Phenotypes')
		then 'phenotypes'
	when (category_name = 'Mutant Alleles')
		then 'alleles'
    when (category_name = 'TDNA-Seq')
        then 'insertions'
	else
		NULL
end as units
from
data_summary_source_units
order by sort_order, datasource_id, gene_count
