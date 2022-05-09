# Create the necessary directories and change to the working directory
mkdir C:\AZ801PacktLab
cd C:\AZ801PacktLab

# Utilize consistent variables to drive the configuration commands below 
# Highlighted areas below will need to be updated if you are opting to use another network interface (per Step 7, optional step)
$VMName='AZ801PacktLab-DC-01','AZ801PacktLab-HV-01','AZ801PacktLab-HV-02','AZ801PacktLab-FS-01'
$VMExternalSwitch='AZ801PacktLabExternal'
$VMInternalSwitch='AZ801PacktLabInternal'
$VMIso='c:\AZ801PacktLab\iso\Server2022Preview.iso'

# Create new virtual switch of type External for use in the AZ801PacktLab
New-VMSwitch -Name $VMExternalSwitch -AllowManagementOS $true -NetAdapterName (Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and !$_.Virtual}).Name

# Create new virtual swicth of type Internal for use in the AZ801PacktLab
New-VMSwitch -name $VMInternalSwitch -SwitchType Internal

# Create new virtual machines of type Standard
Foreach ($VM in $VMName) {
    New-VM -Name $VM -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath ".\VMs\$VM.vhdx" -Path .\VMData -NewVHDSizeBytes 40GB -Generation 2 -Switch $VMInternalSwitch

    # Configure the Hyper-V nested virtual machines by exposing the necessary virtualization features, disabling dynamic memory management, and enabling MAC address spoofing
    if($VM -match '-HV-') {
        Set-VMProcessor -VMName $VM -ExposeVirtualizationExtensions $true
        Set-VMMemory -VMName $VM -DynamicMemoryEnabled $false
        Get-VMNetworkAdapter -VMName $VM | Set-VMNetworkAdapter -MacAddressSpoofing On
    }

    # Add DVD Drive to Virtual Machine
    Add-VMScsiController -VMName $VM
    Add-VMDvdDrive -Path $VMIso -VMName $VM -ControllerNumber 1 -ControllerLocation 0

    # Mount Installation Media on the Virtual Machine
    $VMDvd = Get-VMDvdDrive -VMName $VM

    # Set the ISO/DVD device to be first in boot order for the Virtual Machine
    Set-VMFirmware -VMName $VM -FirstBootDevice $VMDvd

    # Set the Virtual Machine to utilize the TPM key protector
    Set-VMKeyProtector -NewLocalKeyProtector -VMName $VM
    Enable-VMTPM -VMName $VM
}
