Prerequisites:
- A Windows system with:
- WAIK (or ADK for Windows 8 support)
- wim2vhd (http://archive.msdn.microsoft.com/wim2vhd)

1) Extract install.wim file from the ISO with 7-zip:
    "C:\Program Files\7-Zip\7z.exe" x "Windows server 8 beta.iso" sources/install.wim

2) Get latest signed virtio drivers from RedHat:
http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/

3) Add virtio drivers to the wim:
cf. http://technet.microsoft.com/en-us/library/dd744355%28v=ws.10%29.aspx

4) Generate unattend.xml with WAIK (or use a pre-defined one)
- Only use the "specialize" and "OOBE" phases are the others aren't used by wim2vhd
- Remove the computer name (but leave `<ComputerName></ComputerName>`) so that a name is generated without user interaction
- Add scripts to activate remote access (Remote Desktop & WinRM)
  example: see README.md from https://github.com/xebialabs/overthere

5) Create VHD image:
    cscript WIM2VHD.wsf /wim:"C:\DEV\sources\install.wim" /sku:"Windows 7 Professional" /vhd:test.vhd /size:10240 /unattend:Unattend_win7.xml
"preinstall" some files:
check the mergefolder option of wim2vhd + unattended execution of installers

