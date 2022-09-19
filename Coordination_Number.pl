#!perl

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

# Coordination Number Evolution Analysis Tool
# Written by Theall. Zhang
# Ver 1.1

use constant PI => 3.14159265358979323846;

# User Input Section

my $doc = $Documents{"NVE_100ps.xtd"};
my $CNStudyTable = Documents->New("Na_ion_Coordination_Number_Evolution.std");
my $RDFSetA = "Na_ion";
my $RDFSetB = "Oxygens";
my $RDFBinWidth = 0.1;
my $RDFCutoff = 10;
my $CNcutoff = 2.85;

# Count Atoms in the Selected Set

my $Batoms = $doc->UnitCell->Sets($RDFSetB)->Atoms;
my $BAtomcounts = scalar(@$Batoms);

my $Aatoms = $doc->UnitCell->Sets($RDFSetA)->Atoms;
my $AAtomcounts = scalar(@$Aatoms);

# Get PBC Volume 

my $Volume = $doc->SymmetrySystem->Volume;

# Generate Study table 

my $IntegratedCNsheet = $CNStudyTable->ActiveSheet;
$IntegratedCNsheet->ColumnHeading(0) = "Frame";
$IntegratedCNsheet->ColumnHeading(1) = "Coordination Number";

# Main loop

my $numFrames = $doc->Trajectory->NumFrames;

for (my $counter = 1; $counter <= $numFrames; ++$counter) {
#for (my $counter = 1; $counter <= 3; ++$counter) {

	$doc->Trajectory->CurrentFrame = $counter;
	my $tmpdoc = Documents->New("tmp.xsd");
	$tmpdoc->CopyFrom($doc);
	
	$IntegratedCNsheet->Cell($counter-1, 0) = $counter;
	
	# RDF Analysis

	my $results = Modules->Forcite->Analysis->RadialDistributionFunction($tmpdoc, Settings(
		#ActiveDocumentFrameRange => "$counter", 
		RDFBinWidth => $RDFBinWidth, 
		RDFCutoff => $RDFCutoff, 
		RDFSetA => $RDFSetA, 
		RDFSetB => $RDFSetB));
	my $outRDFChart = $results->RDFChart;
	my $outRDFChartAsStudyTable = $results->RDFChartAsStudyTable;
	
	my $columnCount = $outRDFChartAsStudyTable->Sheets(2)->ColumnCount;
	my $rowCount = $outRDFChartAsStudyTable->Sheets(2)->RowCount;
	
	# RDF Studytable contents collection
	
	# Generate a New tmp Studytable
	
	my $tmpStudyTable = Documents->New("Coordination_Number_$counter.std");
	my $calcSheet = $tmpStudyTable->ActiveSheet;
	$calcSheet->ColumnHeading(0) = "r(Angstrom)";
	$calcSheet->ColumnHeading(1) = "g(r)";
	$calcSheet->ColumnHeading(2) = "IntegratedCN";

	# Get r data from RDF studytable
	
	for (my $rownum = 0; $rownum < $rowCount; ++$rownum) {
	
		my $cell = $outRDFChartAsStudyTable->Sheets(2)->Cell($rownum, 0);
		$calcSheet->Cell($rownum, 0) = $cell;
		
	}
	
	# Get coordination number and integrated coordination number data from RDF studytable
	
	my $integratedRDF;
	my $CoordinateNumber;
	my $integratedCN;
		
	for (my $rownum = 0; $rownum < $rowCount; ++$rownum) {
		
		my $r = $outRDFChartAsStudyTable->Sheets(2)->Cell($rownum, 0);
		$calcSheet->Cell($rownum, 0) = $r;
		
		my $gr = $outRDFChartAsStudyTable->Sheets(2)->Cell($rownum, 1);
		$calcSheet->Cell($rownum, 1) = $gr;
		
		$integratedRDF = $integratedRDF + $gr;
		
		$CoordinateNumber = $BAtomcounts * $gr * 4 * PI * $r * $r * $RDFBinWidth / $Volume;
		
		$integratedCN = $integratedCN + $CoordinateNumber;
		
		$calcSheet->Cell($rownum, 2) = $integratedCN;
		
		if ($r == $CNcutoff)
		{
			$IntegratedCNsheet->Cell($counter-1, 1) = $integratedCN;
		}
	
	}
	# Some clean work
	
	$outRDFChart->Discard;
	$outRDFChartAsStudyTable->Discard;
	$tmpdoc->Discard;
	$tmpStudyTable->Discard;
	
}	
	
			
			

