version 1.0
#WORKFLOW DEFINITION
workflow TotalSegmentator {
 input {
   #all the inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here
   
   File seriesInstanceS5cmdUrls

   #Docker Images for each task
   String totalSegmentatorDocker = "imagingdatacommons/totalsegmentator:end_to_end_v1" 

   #Preemptible retries
   Int totalSegmentatorPreemptibleTries = 3

   #Compute CPU configuration
   Int totalSegmentatorCpus = 4
   
   #Compute RAM configuration
   Int totalSegmentatorRAM = 16

   #String downloadDicomAndConvertAndInferenceTotalSegmentatorCpuFamily = 'Intel Cascade Lake' #Because GPUs are available only with N1 family
   String dicomsegAndRadiomicsSR_CpuFamily = 'AMD Rome'   # change name to be consistent with above
   
   #Compute GPU model
   # String totalSegmentatorGpuType = 'nvidia-tesla-t4'
   
   #Compute Datacenter Zones
   String totalSegmentatorZones = "us-central1-a us-central1-b us-central1-c us-central1-f us-east1-b us-east1-c us-east1-d us-west1-a us-west1-b us-west1-c"
   
 }
 #calling totalSegmentatorEndtoEnd Task with the inputs

 call totalSegmentatorEndToEnd{
   input:
    seriesInstanceS5cmdUrls = seriesInstanceS5cmdUrls,
    # dicomToNiftiConverterTool = dicomToNiftiConverterTool,
    totalSegmentatorDocker = totalSegmentatorDocker,
    totalSegmentatorPreemptibleTries = totalSegmentatorPreemptibleTries,
    totalSegmentatorCpus = totalSegmentatorCpus,
    totalSegmentatorRAM = totalSegmentatorRAM,
	dicomsegAndRadiomicsSR_CpuFamily = dicomsegAndRadiomicsSR_CpuFamily,
    # totalSegmentatorGpuType = totalSegmentatorGpuType,
    totalSegmentatorZones = totalSegmentatorZones
}


 output {
  #output notebooks
  
   File endToEndTotalSegmentatorOutputJupyterNotebook = totalSegmentatorEndToEnd.endToEndTotalSegmentatorOutputJupyterNotebook
   File dicomsegAndRadiomicsSR_CompressedFiles = totalSegmentatorEndToEnd.dicomsegAndRadiomicsSR_CompressedFiles
   File pyradiomicsRadiomicsFeatures = totalSegmentatorEndToEnd.pyradiomicsRadiomicsFeatures
   File structuredReportsDICOM = totalSegmentatorEndToEnd.structuredReportsDICOM
   File structuredReportsJSON = totalSegmentatorEndToEnd.structuredReportsJSON
   File endToEndTotalSegmentator_UsageMetrics = totalSegmentatorEndToEnd.endToEndTotalSegmentator_UsageMetrics


   File? dcm2niixErrors = totalSegmentatorEndToEnd.dcm2niixErrors
   File? totalsegmentatorErrors = totalSegmentatorEndToEnd.totalsegmentatorErrors
   File? dicomSegErrors = totalSegmentatorEndToEnd.dicomSegErrors
   File? dicomsegAndRadiomicsSR_RadiomicsErrors = totalSegmentatorEndToEnd.dicomsegAndRadiomicsSR_RadiomicsErrors
   File? dicomsegAndRadiomicsSR_SRErrors = totalSegmentatorEndToEnd.dicomsegAndRadiomicsSR_SRErrors
 }

}

#Task Definitions
task totalSegmentatorEndToEnd{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here
    File seriesInstanceS5cmdUrls
    # String dicomToNiftiConverterTool 
    String totalSegmentatorDocker
    Int totalSegmentatorPreemptibleTries 
    Int totalSegmentatorCpus 
    Int totalSegmentatorRAM 
	String dicomsegAndRadiomicsSR_CpuFamily
    # String totalSegmentatorGpuType 
    String totalSegmentatorZones

 }
 command {
   wget https://raw.githubusercontent.com/ImagingDataCommons/Cloud-Resources-Workflows/main/Notebooks/Totalsegmentator/endToEndTotalSegmentatorNotebook.ipynb
   set -e
   papermill -p csvFilePath ~{seriesInstanceS5cmdUrls} endToEndTotalSegmentatorNotebook.ipynb endToEndTotalSegmentatorOutputJupyterNotebook.ipynb || (>&2 echo "Killed" && exit 1)
 }

 #Run time attributes:
 runtime {
   docker: totalSegmentatorDocker
   cpu: totalSegmentatorCpus
   cpuPlatform: dicomsegAndRadiomicsSR_CpuFamily
   # gpuType: totalSegmentatorGpuType 
   # gpuCount: 1
   zones: totalSegmentatorZones
   memory: totalSegmentatorRAM + " GiB"
   disks: "local-disk 10 HDD"  #ToDo: Dynamically calculate disk space using the no of bytes of yaml file size. 64 characters is the max size I found in a seriesInstanceUID
   preemptible: totalSegmentatorPreemptibleTries
   maxRetries: 3
 }
 output {
   File endToEndTotalSegmentatorOutputJupyterNotebook = "endToEndTotalSegmentatorOutputJupyterNotebook.ipynb"
   File dicomsegAndRadiomicsSR_CompressedFiles = "dicomsegAndRadiomicsSR_DICOMsegFiles.tar.lz4"
   File pyradiomicsRadiomicsFeatures = "pyradiomicsRadiomicsFeatures.tar.lz4"
   File structuredReportsDICOM = "structuredReportsDICOM.tar.lz4"
   File structuredReportsJSON = "structuredReportsJSON.tar.lz4"
   File endToEndTotalSegmentator_UsageMetrics = "endToEndTotalSegmentator_UsageMetrics.lz4"


   File? dcm2niixErrors = 'error_file.txt'
   File? totalsegmentatorErrors = "totalsegmentator_errors.txt"
   File? dicomSegErrors = "itkimage2segimage_error_file.txt"  
   File? dicomsegAndRadiomicsSR_RadiomicsErrors = "radiomics_error_file.txt" 
   File? dicomsegAndRadiomicsSR_SRErrors = "sr_error_file.txt"
   
 }
}
