#cloud service name, source VM name, new VM name, subscription name needed for the input
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
    [string]$SvcName,
  [Parameter(Mandatory=$True)]
    [string]$SourceVMName,
  [Parameter(Mandatory=$True)]
    [string]$NewVMName,
  [Parameter(Mandatory=$True)]
    [string]$Subscription         
)

#log file for script with timestamp
$file = "c:\temp\Renaming_Azure__VM_$SourceVMName{0:MMddyyyy_HHmm}.log" -f (Get-Date)

new-item -path $file -type file -force

$dt = Get-Date -UFormat %c
Write-Host "Renaming VM $SourceVMName in ServiceName $Svcname" -ForegroundColor Yellow
Write-Output "Cloning VM $SourceVMName in ServiceName $Svcname timestamt: $dt" >> $file

#VM object and storing it in the $vm variable.
$vm = Get-AzureVM -ServiceName $SvcName -Name $SourceVMName

#Azure disk information
$OSDisk = $vm | Get-AzureOSDisk

#we have to configure this storage account as current for the subscription I'm using. This is required to create a new VM from a configuration file.
$StorageAccountName = $OSDisk.MediaLink.Host.Split('.')[0]
Set-AzureSubscription –SubscriptionName $Subscription –CurrentStorageAccountName $StorageAccountName

$dt = Get-Date -UFormat %c
Write-Host "Stopping and Deallocating the VM $vmName" -ForegroundColor Yellow
Write-Output "Stopping and Deallocating VM $vmName, timestamp: $dt" >> $file

#updating the log file and console again and then stopping the VM to rename it.
$vm | Stop-Azurevm -Force -Verbose
do{
    sleep 5
    $status = (get-azurevm -ServiceName $SvcName -Name $vmName).InstanceStatus
    }
  until($status -eq "StoppedDeallocated")

sleep 30

$vmxml = "C:\temp\$SourceVMName.xml"
$vm | Export-AzureVM -Path $vmxml

if(Test-Path $vmxml){
  $xml = [xml](Get-Content $vmxml)
  $xml.ChildNodes[1].RoleName = $NewVMName
  $xml.Save($vmxml)
  }
  
$vm | Remove-AzureVM -Verbose
sleep 30
Import-AzureVM -Path $vmxml | New-AzureVm -ServiceName $SvcName
