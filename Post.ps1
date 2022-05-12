# Used to prep-post imaged devices for bitlocker enabling. Pre-cautionary messure
Remove-Item 'C:\Windows\System32\Recovery\ReAgent.xml' -Force -Confirm

# Enable-Bitlocker cmdlet requires a SecureString for its pin, so we provide the pin in plaintext to be converted to a SecureStrong Object.
$SecureString = ConvertTo-SecureString "4257" -AsPlainText -Force

# Enables bitlocker on the C drive and specifies Aes256 as the encryption type, tells the cmdlet to only encypt used space and pipes in the,
# securestring then species that the user should be able to use the TPM and a Pin to unlock bitlocker.
Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -Pin $SecureString -TPMandPinProtector